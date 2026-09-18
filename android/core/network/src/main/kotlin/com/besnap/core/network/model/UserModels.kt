package com.besnap.core.network.model

import com.squareup.moshi.JsonClass

@JsonClass(generateAdapter = true)
data class UserResponse(
    val id: String,
    val email: String?,
    val phone: String?,
    val onboardingDone: Boolean,
    val profile: ProfileDto?,
)

@JsonClass(generateAdapter = true)
data class ProfileDto(
    val id: String,
    val displayName: String,
    val bio: String,
    val gender: String,
    val lookingFor: String,
    val verified: Boolean,
)

@JsonClass(generateAdapter = true)
data class InterestDto(
    val id: String,
    val slug: String,
    val label: String,
    val emoji: String,
)
