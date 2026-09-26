// Root Gradle build for the android/ platform folder. Plugins are declared
// (not applied) in settings.gradle.kts per the modern Gradle plugin-management
// convention; nothing project-wide needs to happen here yet.

tasks.register("clean", Delete::class) {
    delete(rootProject.layout.buildDirectory)
}
