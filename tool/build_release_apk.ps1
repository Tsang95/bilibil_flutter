[CmdletBinding()]
param(
    [string] $DartDefineFile = $env:B_FLUTTER_DART_DEFINE_FILE
)

$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent $PSScriptRoot
$androidDirectory = Join-Path $projectRoot 'android'
$pubspecFile = Join-Path $projectRoot 'pubspec.yaml'
$localPropertiesFile = Join-Path $androidDirectory 'local.properties'
$keyPropertiesFile = Join-Path $androidDirectory 'key.properties'
$gradleWrapper = Join-Path $androidDirectory 'gradlew.bat'
$releaseOutputDirectory = Join-Path $projectRoot 'build\app\outputs\flutter-apk'
$gradleInitScriptFile = Join-Path $projectRoot 'build\.jdk17_gradle_worker.init.gradle'

if ([string]::IsNullOrWhiteSpace($DartDefineFile)) {
    $userProfileDirectory = [Environment]::GetFolderPath(
        [Environment+SpecialFolder]::UserProfile
    )
    $DartDefineFile = Join-Path $userProfileDirectory '.b_flutter\dev_defines.json'
}

if (-not (Test-Path -LiteralPath $DartDefineFile -PathType Leaf)) {
    throw "Dart define file was not found at '$DartDefineFile'. Pass -DartDefineFile or set B_FLUTTER_DART_DEFINE_FILE."
}

try {
    $dartDefineConfig = Get-Content -LiteralPath $DartDefineFile -Raw |
        ConvertFrom-Json
}
catch {
    throw "Dart define file '$DartDefineFile' is not valid JSON."
}

$requiredDartDefines = @(
    'API_DOMAINS'
    'API_SIGNING_KEY'
    'API_RESPONSE_AES_KEY'
    'API_RESPONSE_IV_PREFIX'
    'IDENTITY_CARD_IV_SUFFIX'
    'VIDEO_SIGNING_KEY'
)
$dartDefineProperties = @($dartDefineConfig.PSObject.Properties)
foreach ($requiredDartDefine in $requiredDartDefines) {
    $property = $dartDefineProperties |
        Where-Object { $_.Name -ceq $requiredDartDefine } |
        Select-Object -First 1
    if ($null -eq $property -or
        [string]::IsNullOrWhiteSpace([string]$property.Value)) {
        throw "Dart define '$requiredDartDefine' is missing or empty in '$DartDefineFile'."
    }
}

$encodedDartDefines = $dartDefineProperties | ForEach-Object {
    $value = if ($_.Value -is [bool]) {
        $_.Value.ToString().ToLowerInvariant()
    }
    elseif ($null -eq $_.Value) {
        'null'
    }
    else {
        [string]$_.Value
    }
    $plainDefine = "$($_.Name)=$value"
    [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($plainDefine))
}
$dartDefinesProperty = $encodedDartDefines -join ','

$releaseApkNames = @(
    'app-armeabi-v7a-release.apk'
    'app-arm64-v8a-release.apk'
    'app-x86_64-release.apk'
)

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

$versionLine = Get-Content -LiteralPath $pubspecFile |
    Where-Object { $_ -match '^\s*version\s*:' } |
    Select-Object -First 1
$versionMatch = [regex]::Match(
    $versionLine,
    '^\s*version\s*:\s*([0-9]+(?:\.[0-9]+){2})\+([0-9]+)\s*$'
)
if (-not $versionMatch.Success) {
    throw 'pubspec.yaml must contain a version in the form x.y.z+buildNumber.'
}
$versionName = $versionMatch.Groups[1].Value
$versionCode = $versionMatch.Groups[2].Value

$localPropertyLines = [System.Collections.Generic.List[string]]::new()
if (Test-Path -LiteralPath $localPropertiesFile -PathType Leaf) {
    Get-Content -LiteralPath $localPropertiesFile | ForEach-Object {
        $localPropertyLines.Add($_)
    }
}

function Set-LocalProperty {
    param(
        [Parameter(Mandatory)] [string] $Name,
        [Parameter(Mandatory)] [string] $Value
    )

    $propertyPattern = '^\s*' + [regex]::Escape($Name) + '\s*='
    for ($index = 0; $index -lt $localPropertyLines.Count; $index++) {
        if ($localPropertyLines[$index] -match $propertyPattern) {
            $localPropertyLines[$index] = "$Name=$Value"
            return
        }
    }
    $localPropertyLines.Add("$Name=$Value")
}

Set-LocalProperty -Name 'flutter.versionName' -Value $versionName
Set-LocalProperty -Name 'flutter.versionCode' -Value $versionCode
[System.IO.File]::WriteAllLines(
    $localPropertiesFile,
    $localPropertyLines,
    [System.Text.UTF8Encoding]::new($false)
)

# Gradle 8.0 can reuse the JDK 17 launcher only when no custom daemon JVM
# arguments are requested. Keep its required JPMS access on the launcher and
# run Groovy/Kotlin compilation in-process to avoid the local loopback issue.
$gradleJpmsArguments = @(
    '--add-opens=java.base/java.lang=ALL-UNNAMED'
    '--add-opens=java.base/java.lang.invoke=ALL-UNNAMED'
    '--add-opens=java.base/java.util=ALL-UNNAMED'
    '--add-opens=java.prefs/java.util.prefs=ALL-UNNAMED'
    '--add-opens=java.base/java.nio.charset=ALL-UNNAMED'
    '--add-opens=java.base/java.net=ALL-UNNAMED'
    '--add-opens=java.base/java.util.concurrent.atomic=ALL-UNNAMED'
)

$originalGradleOptions = $env:GRADLE_OPTS
try {
    $gradleInitScriptDirectory = Split-Path -Parent $gradleInitScriptFile
    [System.IO.Directory]::CreateDirectory($gradleInitScriptDirectory) | Out-Null
    [System.IO.File]::WriteAllText(
        $gradleInitScriptFile,
        @'
allprojects {
    tasks.withType(org.gradle.api.tasks.compile.GroovyCompile).configureEach {
        groovyOptions.fork = false
    }
}
'@,
        [System.Text.UTF8Encoding]::new($false)
    )

    $env:GRADLE_OPTS = ($gradleJpmsArguments + @(
        '-Dfile.encoding=UTF-8'
        '-Duser.country=CN'
        '-Duser.language=zh'
        '-Duser.variant='
    )) -join ' '

    Push-Location $androidDirectory
    try {
        & $gradleWrapper ':app:assembleRelease' '--no-daemon' `
            '--init-script' $gradleInitScriptFile `
            '-Dorg.gradle.jvmargs=' `
            '-Pkotlin.compiler.execution.strategy=in-process' `
            "-Pdart-defines=$dartDefinesProperty" `
            '-Ptarget-platform=android-arm,android-arm64,android-x64' `
            '-Psplit-per-abi=true'
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
    if (Test-Path -LiteralPath $gradleInitScriptFile -PathType Leaf) {
        [System.IO.File]::Delete($gradleInitScriptFile)
    }
}

Write-Host "Version: $versionName+$versionCode"
Write-Host "Dart defines: loaded $($dartDefineProperties.Count) values from $DartDefineFile"
foreach ($releaseApkName in $releaseApkNames) {
    $releaseApk = Join-Path $releaseOutputDirectory $releaseApkName
    if (-not (Test-Path -LiteralPath $releaseApk -PathType Leaf)) {
        throw "Gradle completed, but the release APK was not found at '$releaseApk'."
    }

    $apkFile = Get-Item -LiteralPath $releaseApk
    $apkHash = Get-FileHash -LiteralPath $releaseApk -Algorithm SHA256
    Write-Host "Release APK: $($apkFile.FullName)"
    Write-Host "Size: $($apkFile.Length) bytes"
    Write-Host "SHA-256: $($apkHash.Hash)"
}
