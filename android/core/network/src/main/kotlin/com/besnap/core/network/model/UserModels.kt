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

@JsonClass(generateAdapter = true)
data class DiscoverFeedItemDto(
    val userId: String,
    val displayName: String,
    val age: Int,
    val distanceKm: Double,
    val bio: String,
    val interests: List<InterestDto>,
    val photos: List<String>,
    val lookingFor: String
)

@JsonClass(generateAdapter = true)
data class SwipeResponseDto(
    val matched: Boolean,
    val matchId: String? = null
)
