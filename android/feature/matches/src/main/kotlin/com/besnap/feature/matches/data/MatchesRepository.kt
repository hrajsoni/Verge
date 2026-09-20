package com.besnap.feature.matches.data

import com.besnap.core.network.BeSnapApi
import com.besnap.core.network.model.MatchDto
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class MatchesRepository @Inject constructor(
    private val api: BeSnapApi,
) {
    suspend fun getMatches(): Result<List<MatchDto>> = runCatching {
        api.getMatches()
    }
}
