allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)

    // html_editor_enhanced still pulls Android modules fixed to old API
    // levels. Keep the legacy plugins while compiling them against the same
    // API level as the application. API 36 also provides android.window.BackEvent
    // to flutter_inappwebview_android's release R8 classpath.
    if (
        name == "flutter_keyboard_visibility" ||
        name == "flutter_inappwebview_android"
    ) {
        afterEvaluate {
            extensions.configure<com.android.build.api.dsl.LibraryExtension> {
                compileSdk = 36
            }
        }
    }

}

// video_player_android 2.7.1 intentionally targets Java 8 for Android
// compatibility and enables -Werror. JDK 17 reports that source/target level
// as an obsolete "options" warning, so suppress only that warning after the
// plugin has added its strict compiler arguments.
gradle.projectsEvaluated {
    project(":video_player_android")
        .tasks
        .withType<org.gradle.api.tasks.compile.JavaCompile>()
        .configureEach {
            options.compilerArgs.add("-Xlint:-options")
        }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
