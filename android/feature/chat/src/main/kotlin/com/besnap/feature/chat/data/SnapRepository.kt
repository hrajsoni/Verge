package com.besnap.feature.chat.data

import com.besnap.core.network.BeSnapApi
import com.besnap.core.network.model.OpenSnapResponse
import timber.log.Timber
import javax.inject.Inject

class SnapRepository @Inject constructor(
    private val api: BeSnapApi,
) {
    suspend fun openSnap(messageId: String): Result<OpenSnapResponse> = runCatching {
        api.openSnap(messageId)
    }.onFailure { Timber.e(it, "Failed to open snap $messageId") }

    suspend fun markSnapViewed(messageId: String): Result<Unit> = runCatching {
        api.markSnapViewed(messageId)
        Unit
    }.onFailure { Timber.e(it, "Failed to mark snap viewed $messageId") }
}
