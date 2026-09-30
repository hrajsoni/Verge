package com.besnap.feature.profile.data

import com.besnap.core.network.BeSnapApi
import com.besnap.core.network.model.ProfileResponse
import com.besnap.core.network.model.UpdateProfileRequest
import timber.log.Timber
import javax.inject.Inject

class ProfileRepository @Inject constructor(
    private val api: BeSnapApi,
) {
    suspend fun getMyProfile(): Result<ProfileResponse> = runCatching {
        api.getMyProfile()
    }.onFailure { Timber.e(it, "Failed to load profile") }

    suspend fun updateProfile(request: UpdateProfileRequest): Result<ProfileResponse> = runCatching {
        api.updateMyProfile(request)
    }.onFailure { Timber.e(it, "Failed to update profile") }
}
