package com.besnap.core.network.model

import com.squareup.moshi.JsonClass

@JsonClass(generateAdapter = true)
data class GoogleAuthRequest(
    val idToken: String,
)

@JsonClass(generateAdapter = true)
data class AuthResponse(
    val accessToken: String,
    val isNewUser: Boolean = false,
    val onboardingDone: Boolean = false,
)
