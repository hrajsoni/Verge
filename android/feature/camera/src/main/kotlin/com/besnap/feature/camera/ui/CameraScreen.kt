package com.besnap.feature.camera.ui

import android.Manifest
import android.view.LayoutInflater
import android.view.ViewStub
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Cameraswitch
import androidx.compose.material.icons.filled.Close
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalLifecycleOwner
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.viewinterop.AndroidView
import androidx.hilt.navigation.compose.hiltViewModel
import com.besnap.feature.camera.BuildConfig
import com.besnap.feature.camera.CameraViewModel
import com.besnap.feature.camera.R
import com.besnap.feature.camera.model.CameraLensFacing
import com.snap.camerakit.Session
import com.snap.camerakit.invoke
import com.snap.camerakit.lenses.LensesComponent
import com.snap.camerakit.lenses.LensesComponent.Repository.QueryCriteria.Available
import com.snap.camerakit.lenses.whenHasFirst
import com.snap.camerakit.support.camerax.CameraXImageProcessorSource
import com.snap.camerakit.supported
import timber.log.Timber

private val SNAP_DURATIONS = listOf(1, 3, 5, 10, 15, 30)

@Composable
fun CameraScreen(
    onCloseClick: () -> Unit,
    onGalleryClick: () -> Unit,
    modifier: Modifier = Modifier,
    viewModel: CameraViewModel = hiltViewModel(),
) {
    val context = LocalContext.current
    val lifecycleOwner = LocalLifecycleOwner.current
    val uiState by viewModel.uiState.collectAsState()
    val lenses by viewModel.lenses.collectAsState()
    val activeLensIndex by viewModel.activeLensIndex.collectAsState()
    val snapDuration by viewModel.snapDurationSeconds.collectAsState()
    val replayAllowed by viewModel.snapReplayAllowed.collectAsState()

    if (uiState.capturedMedia != null) {
        CapturePreviewScreen(
            media = uiState.capturedMedia!!,
            snapDurationSeconds = snapDuration,
            replayAllowed = replayAllowed,
            onRetake = viewModel::onRetake,
            onSend = { /* handle send */ },
        )
        return
    }

    if (!supported(context)) {
        Box(modifier = modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
            Text("Camera Kit is not supported on this device.", color = Color.White)
        }
        return
    }

    // Camera Kit session and image source managed as remembered objects tied to lifecycle
    val imageProcessorSource = remember {
        CameraXImageProcessorSource(
            context = context,
            lifecycleOwner = lifecycleOwner,
        )
    }

    var cameraKitSession by remember { mutableStateOf<Session?>(null) }

    // Start/stop preview based on lens facing
    LaunchedEffect(uiState.lensFacing) {
        imageProcessorSource.startPreview(uiState.lensFacing == CameraLensFacing.FRONT)
    }

    // Select lens in Camera Kit when activeLensIndex changes
    LaunchedEffect(activeLensIndex, lenses) {
        val session = cameraKitSession ?: return@LaunchedEffect
        val index = activeLensIndex
        if (index != null && index < lenses.size) {
            session.lenses.processor.apply(lenses[index])
        } else {
            session.lenses.processor.clear()
        }
    }

    DisposableEffect(Unit) {
        onDispose {
            cameraKitSession?.close()
            cameraKitSession = null
        }
    }

    Box(modifier = modifier.fillMaxSize().background(Color.Black)) {
        // Camera Kit preview via AndroidView
        AndroidView(
            factory = { ctx ->
                LayoutInflater.from(ctx).inflate(R.layout.camera_kit_layout, null).also { root ->
                    val viewStub = root.findViewById<ViewStub>(R.id.camera_kit_stub)
                    val apiToken = if (BuildConfig.DEBUG) {
                        BuildConfig.CAMERA_KIT_API_TOKEN_STAGING
                    } else {
                        BuildConfig.CAMERA_KIT_API_TOKEN_PRODUCTION
                    }
                    val session = Session(context = ctx) {
                        apiToken(apiToken)
                        imageProcessorSource(imageProcessorSource)
                        attachTo(viewStub)
                    }
                    cameraKitSession = session

                    // Load lenses from group
                    session.lenses.repository.observe(
                        Available(BuildConfig.CAMERA_KIT_LENS_GROUP_ID)
                    ) { result ->
                        if (result is LensesComponent.Repository.Result.Some) {
                            val loaded = result.lenses
                            viewModel.onLensesLoaded(loaded)
                        } else {
                            viewModel.onLensesLoaded(emptyList())
                        }
                        
                        // Auto-apply the first lens
                        result.whenHasFirst { firstLens ->
                            session.lenses.processor.apply(firstLens)
                            viewModel.selectLens(0)
                        }
                    }
                }
            },
            modifier = Modifier.fillMaxSize(),
        )

        // Top controls
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .statusBarsPadding()
                .padding(horizontal = 16.dp, vertical = 8.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically,
        ) {
            IconButton(
                onClick = onCloseClick,
                modifier = Modifier
                    .size(40.dp)
                    .background(Color.Black.copy(alpha = 0.4f), CircleShape)
            ) {
                Icon(Icons.Default.Close, contentDescription = "Close", tint = Color.White)
            }

            IconButton(
                onClick = viewModel::toggleCameraFacing,
                modifier = Modifier
                    .size(40.dp)
                    .background(Color.Black.copy(alpha = 0.4f), CircleShape)
            ) {
                Icon(Icons.Default.Cameraswitch, contentDescription = "Flip Camera", tint = Color.White)
            }
        }

        // Bottom controls
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .align(Alignment.BottomCenter)
                .navigationBarsPadding()
                .padding(bottom = 16.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            // Snap duration selector
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp, vertical = 8.dp),
                horizontalArrangement = Arrangement.Center,
                verticalAlignment = Alignment.CenterVertically,
            ) {
                SNAP_DURATIONS.forEach { duration ->
                    val isSelected = duration == snapDuration
                    Box(
                        modifier = Modifier
                            .padding(horizontal = 6.dp)
                            .size(if (isSelected) 40.dp else 34.dp)
                            .clip(CircleShape)
                            .background(
                                if (isSelected) MaterialTheme.colorScheme.primary
                                else Color.White.copy(alpha = 0.25f)
                            )
                            .clickable { viewModel.setSnapDuration(duration) },
                        contentAlignment = Alignment.Center,
                    ) {
                        Text(
                            text = if (duration < 60) "${duration}s" else "${duration / 60}m",
                            color = Color.White,
                            fontSize = 11.sp,
                            fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Normal,
                        )
                    }
                }
            }

            Spacer(modifier = Modifier.height(8.dp))

            // Lens carousel
            if (lenses.isNotEmpty()) {
                LazyRow(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(vertical = 8.dp),
                    contentPadding = PaddingValues(horizontal = 16.dp),
                    horizontalArrangement = Arrangement.spacedBy(10.dp),
                ) {
                    // "No lens" option
                    item {
                        LensCarouselItem(
                            label = "Off",
                            isSelected = activeLensIndex == null,
                            onClick = { viewModel.clearLens() },
                        )
                    }
                    itemsIndexed(lenses) { index, lens ->
                        LensCarouselItem(
                            label = lens.name?.ifBlank { "Lens ${index + 1}" } ?: "Lens ${index + 1}",
                            isSelected = activeLensIndex == index,
                            onClick = { viewModel.selectLens(index) },
                        )
                    }
                }
            }

            Spacer(modifier = Modifier.height(8.dp))

            // Capture button
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 32.dp),
                horizontalArrangement = Arrangement.Center,
                verticalAlignment = Alignment.CenterVertically,
            ) {
                // Replay toggle
                Column(
                    horizontalAlignment = Alignment.CenterHorizontally,
                    modifier = Modifier.weight(1f)
                ) {
                    Switch(
                        checked = replayAllowed,
                        onCheckedChange = { viewModel.toggleReplay() },
                        colors = SwitchDefaults.colors(
                            checkedTrackColor = MaterialTheme.colorScheme.primary
                        )
                    )
                    Text("Replay", color = Color.White, fontSize = 11.sp)
                }

                // Shutter button
                Box(
                    modifier = Modifier
                        .size(80.dp)
                        .border(4.dp, Color.White, CircleShape)
                        .padding(6.dp)
                        .clip(CircleShape)
                        .background(Color.White)
                        .clickable {
                            // Trigger capture — CapturePreviewScreen will handle upload
                            // For now, signal a "captured" state with a placeholder URI
                            // In a full implementation, use CameraX ImageCapture use case
                            Timber.d("Shutter pressed")
                        },
                )

                Spacer(modifier = Modifier.weight(1f))
            }
        }
    }
}

@Composable
private fun LensCarouselItem(
    label: String,
    isSelected: Boolean,
    onClick: () -> Unit,
) {
    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        modifier = Modifier.clickable(onClick = onClick),
    ) {
        Box(
            modifier = Modifier
                .size(56.dp)
                .clip(CircleShape)
                .background(if (isSelected) MaterialTheme.colorScheme.primary else Color.White.copy(alpha = 0.2f))
                .border(
                    width = if (isSelected) 2.dp else 0.dp,
                    color = if (isSelected) Color.White else Color.Transparent,
                    shape = CircleShape,
                ),
            contentAlignment = Alignment.Center,
        ) {
            Text(
                text = label.take(2).uppercase(),
                color = Color.White,
                fontSize = 14.sp,
                fontWeight = FontWeight.Bold,
            )
        }
        Spacer(modifier = Modifier.height(4.dp))
        Text(
            text = label.take(8),
            color = Color.White,
            fontSize = 10.sp,
        )
    }
}
