package com.besnap.feature.camera.ui

import android.Manifest
import android.content.Context
import android.net.Uri
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.camera.core.ImageCapture
import androidx.camera.core.ImageCaptureException
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.Button
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.core.content.ContextCompat
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.LocalLifecycleOwner
import com.besnap.core.permissions.PermissionManager
import com.besnap.feature.camera.CameraViewModel
import java.io.File
import timber.log.Timber

@Composable
fun CameraScreen(
    onCloseClick: () -> Unit,
    onGalleryClick: () -> Unit,
    modifier: Modifier = Modifier,
    viewModel: CameraViewModel = hiltViewModel()
) {
    val context = LocalContext.current
    var hasCameraPermission by remember { mutableStateOf(PermissionManager.hasCameraPermission(context)) }
    var hasAudioPermission by remember { mutableStateOf(PermissionManager.hasAudioPermission(context)) }

    val permissionLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.RequestMultiplePermissions()
    ) { permissions ->
        hasCameraPermission = permissions[Manifest.permission.CAMERA] ?: hasCameraPermission
        hasAudioPermission = permissions[Manifest.permission.RECORD_AUDIO] ?: hasAudioPermission
    }

    LaunchedEffect(Unit) {
        if (!hasCameraPermission || !hasAudioPermission) {
            permissionLauncher.launch(
                arrayOf(Manifest.permission.CAMERA, Manifest.permission.RECORD_AUDIO)
            )
        }
    }

    if (hasCameraPermission && hasAudioPermission) {
        CameraContent(
            viewModel = viewModel,
            onCloseClick = onCloseClick,
            onGalleryClick = onGalleryClick,
            modifier = modifier
        )
    } else {
        Box(modifier = modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                Text("Camera and Audio permissions are required")
                Button(onClick = {
                    permissionLauncher.launch(
                        arrayOf(Manifest.permission.CAMERA, Manifest.permission.RECORD_AUDIO)
                    )
                }) {
                    Text("Grant Permissions")
                }
            }
        }
    }
}

@Composable
fun CameraContent(
    viewModel: CameraViewModel,
    onCloseClick: () -> Unit,
    onGalleryClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    val uiState by viewModel.uiState.collectAsState()
    val context = LocalContext.current
    val lifecycleOwner = LocalLifecycleOwner.current

    val imageCapture = remember { ImageCapture.Builder().build() }

    Box(modifier = modifier.fillMaxSize()) {
        if (uiState.capturedMedia == null) {
            CameraPreview(
                lensFacing = uiState.lensFacing,
                onCameraProviderReady = { provider, previewView ->
                    try {
                        val cameraSelector = androidx.camera.core.CameraSelector.Builder()
                            .requireLensFacing(
                                if (uiState.lensFacing == com.besnap.feature.camera.model.CameraLensFacing.FRONT)
                                    androidx.camera.core.CameraSelector.LENS_FACING_FRONT
                                else
                                    androidx.camera.core.CameraSelector.LENS_FACING_BACK
                            )
                            .build()
                        val preview = androidx.camera.core.Preview.Builder().build().apply {
                            setSurfaceProvider(previewView.surfaceProvider)
                        }
                        provider.unbindAll()
                        provider.bindToLifecycle(
                            lifecycleOwner,
                            cameraSelector,
                            preview,
                            imageCapture
                        )
                    } catch (e: Exception) {
                        Timber.e(e, "Use case binding failed")
                    }
                }
            )

            CameraControls(
                flashMode = uiState.flashMode,
                isRecording = uiState.isRecording,
                activeFilterIndex = uiState.activeFilterIndex,
                onCloseClick = onCloseClick,
                onFlashToggle = viewModel::toggleFlash,
                onSettingsClick = { /* TODO */ },
                onFilterSelected = viewModel::setActiveFilterIndex,
                onGalleryClick = onGalleryClick,
                onShutterTap = {
                    takePhoto(context, imageCapture) { uri ->
                        viewModel.onCapturePhoto(uri)
                    }
                },
                onShutterLongPress = { viewModel.onStartRecording() },
                onShutterRelease = {
                    if (uiState.isRecording) {
                        viewModel.onStopRecording(Uri.EMPTY, 5000L)
                    }
                },
                onFlipCameraClick = viewModel::toggleCameraFacing
            )
        } else {
            CapturePreviewScreen(
                media = uiState.capturedMedia!!,
                onRetake = viewModel::onRetake,
                onSend = { viewModel.onSend("test_recipient") }
            )
        }
    }
}

private fun takePhoto(
    context: Context,
    imageCapture: ImageCapture,
    onPhotoCaptured: (Uri) -> Unit
) {
    val photoFile = File(
        context.getExternalFilesDir(android.os.Environment.DIRECTORY_PICTURES),
        "be_snap_${System.currentTimeMillis()}.jpg"
    )
    val outputOptions = ImageCapture.OutputFileOptions.Builder(photoFile).build()

    imageCapture.takePicture(
        outputOptions,
        ContextCompat.getMainExecutor(context),
        object : ImageCapture.OnImageSavedCallback {
            override fun onImageSaved(outputFileResults: ImageCapture.OutputFileResults) {
                val savedUri = Uri.fromFile(photoFile)
                onPhotoCaptured(savedUri)
            }

            override fun onError(exception: ImageCaptureException) {
                Timber.e(exception, "Photo capture failed")
            }
        }
    )
}
