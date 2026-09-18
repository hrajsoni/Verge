package com.besnap.feature.camera

import android.net.Uri
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.besnap.feature.camera.model.CameraLensFacing
import com.besnap.feature.camera.model.CameraState
import com.besnap.feature.camera.model.CaptureMode
import com.besnap.feature.camera.model.CapturedMedia
import com.besnap.feature.camera.model.FlashMode
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import timber.log.Timber
import javax.inject.Inject

@HiltViewModel
class CameraViewModel @Inject constructor() : ViewModel() {

    private val _uiState = MutableStateFlow(CameraState())
    val uiState: StateFlow<CameraState> = _uiState.asStateFlow()

    fun toggleCameraFacing() {
        _uiState.update { state ->
            val newFacing = if (state.lensFacing == CameraLensFacing.FRONT) {
                CameraLensFacing.BACK
            } else {
                CameraLensFacing.FRONT
            }
            state.copy(lensFacing = newFacing)
        }
    }

    fun toggleFlash() {
        _uiState.update { state ->
            val newFlash = when (state.flashMode) {
                FlashMode.OFF -> FlashMode.ON
                FlashMode.ON -> FlashMode.AUTO
                FlashMode.AUTO -> FlashMode.OFF
            }
            state.copy(flashMode = newFlash)
        }
    }

    fun onCapturePhoto(uri: Uri, isSnap: Boolean = true) {
        Timber.d("Photo captured: $uri")
        _uiState.update { state ->
            state.copy(
                capturedMedia = CapturedMedia(
                    uri = uri,
                    mimeType = "image/jpeg",
                    isSnap = isSnap
                )
            )
        }
    }

    fun onStartRecording() {
        _uiState.update { it.copy(isRecording = true, captureMode = CaptureMode.VIDEO) }
    }

    fun onStopRecording(uri: Uri, durationMs: Long) {
        Timber.d("Video recorded: $uri")
        _uiState.update { state ->
            state.copy(
                isRecording = false,
                recordingDurationMs = durationMs,
                capturedMedia = CapturedMedia(
                    uri = uri,
                    mimeType = "video/mp4",
                    isSnap = true,
                    durationMs = durationMs
                )
            )
        }
    }

    fun onRetake() {
        _uiState.update { state ->
            state.copy(capturedMedia = null, recordingDurationMs = 0L)
        }
    }

    fun onSend(recipientId: String) {
        val media = _uiState.value.capturedMedia
        Timber.d("Sending media ${media?.uri} to $recipientId")
        // Implementation for sending media
    }

    fun setActiveFilterIndex(index: Int) {
        _uiState.update { it.copy(activeFilterIndex = index) }
    }
}
