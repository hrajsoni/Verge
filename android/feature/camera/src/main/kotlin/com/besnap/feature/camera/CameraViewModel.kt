package com.besnap.feature.camera

import android.net.Uri
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.besnap.feature.camera.model.CameraLensFacing
import com.besnap.feature.camera.model.CameraState
import com.besnap.feature.camera.model.CaptureMode
import com.besnap.feature.camera.model.CapturedMedia
import com.besnap.feature.camera.model.FlashMode
import com.snap.camerakit.lenses.LensesComponent
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import timber.log.Timber
import javax.inject.Inject

import android.content.Context
import okhttp3.OkHttpClient
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.RequestBody.Companion.toRequestBody
import kotlinx.coroutines.launch
import com.besnap.core.network.BeSnapApi
import com.besnap.core.network.model.MediaUploadRequest
import com.besnap.core.network.model.SendMessageRequest

@HiltViewModel
class CameraViewModel @Inject constructor(
    private val api: BeSnapApi
) : ViewModel() {

    private val _uiState = MutableStateFlow(CameraState())
    val uiState: StateFlow<CameraState> = _uiState.asStateFlow()

    // Lenses loaded from Camera Kit
    private val _lenses = MutableStateFlow<List<LensesComponent.Lens>>(emptyList())
    val lenses: StateFlow<List<LensesComponent.Lens>> = _lenses.asStateFlow()

    private val _activeLensIndex = MutableStateFlow<Int?>(null)
    val activeLensIndex: StateFlow<Int?> = _activeLensIndex.asStateFlow()

    // Snap settings
    private val _snapDurationSeconds = MutableStateFlow(5)
    val snapDurationSeconds: StateFlow<Int> = _snapDurationSeconds.asStateFlow()

    private val _snapReplayAllowed = MutableStateFlow(false)
    val snapReplayAllowed: StateFlow<Boolean> = _snapReplayAllowed.asStateFlow()

    fun onLensesLoaded(loaded: List<LensesComponent.Lens>) {
        _lenses.value = loaded
    }

    fun selectLens(index: Int) {
        _activeLensIndex.value = index
    }

    fun clearLens() {
        _activeLensIndex.value = null
    }

    fun setSnapDuration(seconds: Int) {
        _snapDurationSeconds.value = seconds
    }

    fun toggleReplay() {
        _snapReplayAllowed.update { !it }
    }

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
    }

    fun uploadAndSendSnap(
        context: Context,
        fileUri: Uri,
        mimeType: String,
        recipientConversationId: String,
        onSuccess: () -> Unit,
        onError: (String) -> Unit,
    ) {
        viewModelScope.launch {
            _uiState.update { it.copy(isUploading = true) }
            try {
                // 1. Request presigned upload URL
                val uploadResp = api.requestUploadUrl(MediaUploadRequest(mimeType = mimeType))
                // 2. PUT file to S3 presigned URL
                val fileBytes = context.contentResolver.openInputStream(fileUri)?.use { it.readBytes() }
                    ?: throw IllegalStateException("Cannot read file")
                // Use OkHttp directly for the S3 PUT
                val okClient = OkHttpClient()
                val putRequest = okhttp3.Request.Builder()
                    .url(uploadResp.uploadUrl)
                    .put(fileBytes.toRequestBody(mimeType.toMediaType()))
                    .build()
                val putResponse = okClient.newCall(putRequest).execute()
                if (!putResponse.isSuccessful) throw IllegalStateException("S3 upload failed: ${putResponse.code}")
                // 3. Send message with mediaId
                api.sendMessage(
                    conversationId = recipientConversationId,
                    request = SendMessageRequest(
                        content = "",
                        messageType = "SNAP",
                        mediaId = uploadResp.mediaId,
                        snapDurationSeconds = _snapDurationSeconds.value,
                        allowReplay = _snapReplayAllowed.value,
                    )
                )
                _uiState.update { it.copy(isUploading = false) }
                onSuccess()
            } catch (e: Exception) {
                Timber.e(e, "Snap upload failed")
                _uiState.update { it.copy(isUploading = false) }
                onError(e.message ?: "Upload failed")
            }
        }
    }

    fun setActiveFilterIndex(index: Int) {
        _uiState.update { it.copy(activeFilterIndex = index) }
    }
}
