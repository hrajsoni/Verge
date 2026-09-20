package com.besnap.feature.onboarding.data

import com.besnap.core.network.BeSnapApi
import com.besnap.core.network.model.CompleteOnboardingRequest
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class OnboardingRepository @Inject constructor(
    private val api: BeSnapApi,
) {
    suspend fun completeOnboarding(request: CompleteOnboardingRequest): Result<Unit> {
        return try {
            api.completeOnboarding(request)
            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
}
