package com.besnap.feature.camera.model

import android.net.Uri

enum class CameraLensFacing {
    FRONT, BACK
}

enum class FlashMode {
    OFF, ON, AUTO
}

enum class CaptureMode {
    PHOTO, VIDEO
}

data class CapturedMedia(
    val uri: Uri,
    val mimeType: String,
    val isSnap: Boolean,
    val durationMs: Long? = null
)

data class CameraState(
    val lensFacing: CameraLensFacing = CameraLensFacing.FRONT,
    val flashMode: FlashMode = FlashMode.OFF,
    val captureMode: CaptureMode = CaptureMode.PHOTO,
    val isRecording: Boolean = false,
    val recordingDurationMs: Long = 0L,
    val activeFilterIndex: Int = 0,
    val capturedMedia: CapturedMedia? = null
)
