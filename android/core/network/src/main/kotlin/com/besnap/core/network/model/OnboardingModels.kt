package com.besnap.core.network.model

import com.squareup.moshi.JsonClass

@JsonClass(generateAdapter = true)
data class CompleteOnboardingRequest(
    val displayName: String,
    val dateOfBirth: String,       // ISO format: "1995-04-12"
    val gender: String,
    val lookingFor: String,
    val interestIds: List<String> = emptyList(),
    val minAge: Int,
    val maxAge: Int,
    val maxDistanceKm: Int,
    val genders: List<String>,
    val latitude: Double,
    val longitude: Double,
    val bio: String = "",
)

@JsonClass(generateAdapter = true)
data class OnboardingResponse(
    val success: Boolean,
)
