package com.besnap.core.network.model

import com.squareup.moshi.JsonClass

@JsonClass(generateAdapter = true)
data class MediaUploadRequest(
    val mimeType: String,
    val category: String = "SNAP_MEDIA",
)

@JsonClass(generateAdapter = true)
data class MediaUploadResponse(
    val mediaId: String,
    val uploadUrl: String,
    val objectKey: String,
)

@JsonClass(generateAdapter = true)
data class OpenSnapResponse(
    val viewUrl: String,
    val viewState: String,
    val viewDurationSeconds: Int,
    val canReplay: Boolean,
)
