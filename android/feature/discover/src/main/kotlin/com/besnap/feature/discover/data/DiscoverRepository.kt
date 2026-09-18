package com.besnap.feature.discover.data

import com.besnap.core.common.BeSnapResult
import com.besnap.core.network.BeSnapApi
import com.besnap.core.network.model.SwipeResponseDto
import com.besnap.feature.discover.model.DiscoverCard
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import javax.inject.Inject

class DiscoverRepository @Inject constructor(
    private val api: BeSnapApi
) {
    suspend fun getFeed(): BeSnapResult<List<DiscoverCard>> = withContext(Dispatchers.IO) {
        try {
            val response = api.getFeed()
            val cards = response.map { dto ->
                DiscoverCard(
                    userId = dto.userId,
                    displayName = dto.displayName,
                    age = dto.age,
                    distanceLabel = "📍 ${dto.distanceKm} km away",
                    bio = dto.bio,
                    interests = dto.interests.map { "${it.emoji} ${it.label}" },
                    photos = dto.photos,
                    lookingFor = dto.lookingFor
                )
            }
            BeSnapResult.Success(cards)
        } catch (e: Exception) {
            BeSnapResult.Error("Failed to fetch feed", e)
        }
    }

    suspend fun likeUser(userId: String): BeSnapResult<SwipeResponseDto> = withContext(Dispatchers.IO) {
        try {
            val response = api.likeUser(userId)
            BeSnapResult.Success(response)
        } catch (e: Exception) {
            BeSnapResult.Error("Failed to like user", e)
        }
    }

    suspend fun passUser(userId: String): BeSnapResult<Unit> = withContext(Dispatchers.IO) {
        try {
            api.passUser(userId)
            BeSnapResult.Success(Unit)
        } catch (e: Exception) {
            BeSnapResult.Error("Failed to pass user", e)
        }
    }
}
