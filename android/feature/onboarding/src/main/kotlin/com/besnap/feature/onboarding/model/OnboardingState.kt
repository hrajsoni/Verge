package com.besnap.feature.onboarding.model

enum class OnboardingStep {
    WELCOME, AUTH, NAME_DOB, PHOTO, INTERESTS, LOOKING_FOR, DISCOVERY_PREFS, LOCATION, COMPLETE
}

enum class Gender {
    MAN, WOMAN, NON_BINARY, OTHER
}

enum class LookingFor {
    FRIENDS, DATING, FRIENDS_AND_DATING
}

data class OnboardingData(
    val displayName: String = "",
    val dob: String = "",
    val selectedInterests: Set<String> = emptySet(),
    val lookingFor: LookingFor = LookingFor.FRIENDS,
    val minAge: Int = 18,
    val maxAge: Int = 50,
    val maxDistanceKm: Int = 50,
    val interestedInGenders: Set<Gender> = emptySet(),
    val bio: String = "",
    val gender: Gender? = null
)
