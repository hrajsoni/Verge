pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
        maven(url = "https://storage.googleapis.com/snap-kit-build/maven")
    }
}

rootProject.name = "BeSnap"

include(":app")
include(":core:common")
include(":core:network")
include(":core:database")
include(":core:auth")
include(":core:design")
include(":core:media")
include(":core:permissions")
include(":feature:onboarding")
include(":feature:discover")
include(":feature:matches")
include(":feature:chat")
include(":feature:camera")
include(":feature:calls")
include(":feature:profile")
include(":feature:notifications")
include(":feature:safety")
