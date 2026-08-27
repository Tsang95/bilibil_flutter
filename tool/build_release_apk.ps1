[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent $PSScriptRoot
$androidDirectory = Join-Path $projectRoot 'android'
$keyPropertiesFile = Join-Path $androidDirectory 'key.properties'
$gradleWrapper = Join-Path $androidDirectory 'gradlew.bat'
$releaseApk = Join-Path $projectRoot 'build\app\outputs\flutter-apk\app-release.apk'

$configuredSigningKeys = @()
if (Test-Path -LiteralPath $keyPropertiesFile -PathType Leaf) {
    $configuredSigningKeys = Get-Content -LiteralPath $keyPropertiesFile |
        Where-Object { $_ -match '^\s*[^#][^=]*=' } |
        ForEach-Object { ($_ -split '=', 2)[0].Trim() }
}

$signingSources = @{
    storeFile     = 'ANDROID_KEYSTORE_FILE'
    storePassword = 'ANDROID_KEYSTORE_PASSWORD'
    keyAlias      = 'ANDROID_KEY_ALIAS'
    keyPassword   = 'ANDROID_KEY_PASSWORD'
}
foreach ($signingKey in $signingSources.Keys) {
    $environmentName = $signingSources[$signingKey]
    $environmentValue = [Environment]::GetEnvironmentVariable($environmentName)
    if ($configuredSigningKeys -notcontains $signingKey -and
        [string]::IsNullOrWhiteSpace($environmentValue)) {
        throw "Missing release signing value '$signingKey'. Configure android/key.properties or $environmentName."
    }
}

if (-not $env:JAVA_HOME -or
    -not (Test-Path -LiteralPath (Join-Path $env:JAVA_HOME 'bin\java.exe') -PathType Leaf)) {
    throw 'JAVA_HOME must point to a valid JDK installation.'
}

# Running Gradle in the launcher JVM avoids a Windows/JDK loopback-channel
# failure seen when this machine starts Gradle and Java compiler daemons.
$gradleJpmsArguments = @(
    '--add-opens=java.base/java.lang=ALL-UNNAMED'
    '--add-opens=java.base/java.lang.invoke=ALL-UNNAMED'
    '--add-opens=java.base/java.util=ALL-UNNAMED'
    '--add-opens=java.prefs/java.util.prefs=ALL-UNNAMED'
    '--add-exports=jdk.compiler/com.sun.tools.javac.api=ALL-UNNAMED'
    '--add-exports=jdk.compiler/com.sun.tools.javac.util=ALL-UNNAMED'
    '--add-opens=java.base/java.nio.charset=ALL-UNNAMED'
    '--add-opens=java.base/java.net=ALL-UNNAMED'
    '--add-opens=java.base/java.util.concurrent.atomic=ALL-UNNAMED'
    '--add-opens=java.xml/javax.xml.namespace=ALL-UNNAMED'
)
$gradleJvmArguments = (@(
        '-Xmx8G'
        '-XX:MaxMetaspaceSize=4G'
        '-XX:ReservedCodeCacheSize=512m'
        '-XX:+HeapDumpOnOutOfMemoryError'
    ) + $gradleJpmsArguments) -join ' '

$originalGradleOptions = $env:GRADLE_OPTS
try {
    $env:GRADLE_OPTS = @(
        $gradleJvmArguments
        '-Dfile.encoding=UTF-8'
        '-Duser.country=CN'
        '-Duser.language=zh'
        '-Duser.variant='
        '-Dorg.gradle.internal.instrumentation.agent=false'
    ) -join ' '

    Push-Location $androidDirectory
    try {
        & $gradleWrapper ':app:assembleRelease' '--no-daemon' `
            '-Dorg.gradle.internal.instrumentation.agent=false' `
            "-Dorg.gradle.jvmargs=$gradleJvmArguments"
        if ($LASTEXITCODE -ne 0) {
            throw "Release APK build failed with exit code $LASTEXITCODE."
        }
    }
    finally {
        Pop-Location
    }
}
finally {
    $env:GRADLE_OPTS = $originalGradleOptions
}

if (-not (Test-Path -LiteralPath $releaseApk -PathType Leaf)) {
    throw "Gradle completed, but the release APK was not found at '$releaseApk'."
}

$apkFile = Get-Item -LiteralPath $releaseApk
$apkHash = Get-FileHash -LiteralPath $releaseApk -Algorithm SHA256
Write-Host "Release APK: $($apkFile.FullName)"
Write-Host "Size: $($apkFile.Length) bytes"
Write-Host "SHA-256: $($apkHash.Hash)"
