package com.besnap.core.network.model

import com.squareup.moshi.JsonClass

@JsonClass(generateAdapter = true)
data class ProfileResponse(
    val id: String,
    val displayName: String,
    val bio: String?,
    val age: Int?,
    val gender: String?,
    val photoUrl: String?,
    val onboardingDone: Boolean,
)

@JsonClass(generateAdapter = true)
data class UpdateProfileRequest(
    val displayName: String?,
    val bio: String?,
    val gender: String?,
)
