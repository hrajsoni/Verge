package com.besnap.feature.camera.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.LocalFireDepartment
import androidx.compose.material.icons.filled.Send
import androidx.compose.material3.Button
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.unit.dp
import coil.compose.AsyncImage
import com.besnap.feature.camera.model.CapturedMedia

@Composable
fun CapturePreviewScreen(
    media: CapturedMedia,
    snapDurationSeconds: Int = 5,
    replayAllowed: Boolean = false,
    onRetake: () -> Unit,
    onSend: () -> Unit,
    modifier: Modifier = Modifier
) {
    Box(modifier = modifier.fillMaxSize().background(Color.Black)) {
        // Preview content
        if (media.mimeType.startsWith("image/")) {
            AsyncImage(
                model = media.uri,
                contentDescription = "Captured Image",
                modifier = Modifier.fillMaxSize(),
                contentScale = ContentScale.Crop
            )
        } else {
            // For simplicity, just showing text for video
            Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                Text(text = "Video Preview: ${media.uri}", color = Color.White)
            }
        }

        // Top bar
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp)
                .align(Alignment.TopCenter),
            verticalAlignment = Alignment.CenterVertically
        ) {
            IconButton(onClick = onRetake) {
                Icon(Icons.Default.Close, contentDescription = "Retake", tint = Color.White)
            }
            Spacer(modifier = Modifier.weight(1f))
            Text(
                text = "⏱ ${snapDurationSeconds}s · Replay: ${if (replayAllowed) "On" else "Off"}",
                color = Color.White,
                modifier = Modifier
                    .background(Color.Black.copy(alpha = 0.5f), shape = androidx.compose.foundation.shape.RoundedCornerShape(8.dp))
                    .padding(horizontal = 8.dp, vertical = 4.dp)
            )
        }

        // Bottom bar
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp)
                .align(Alignment.BottomCenter),
            verticalAlignment = Alignment.CenterVertically
        ) {
            // "Send as Snap" toggle button (yellow flame/snap icon)
            IconButton(onClick = { /* Toggle snap mode */ }) {
                Icon(
                    Icons.Default.LocalFireDepartment,
                    contentDescription = "Send as Snap",
                    tint = if (media.isSnap) Color.Yellow else Color.White
                )
            }
            
            Spacer(modifier = Modifier.weight(1f))
            
            Button(onClick = onSend) {
                Text("Send")
                Icon(Icons.Default.Send, contentDescription = null, modifier = Modifier.padding(start = 8.dp))
            }
        }
    }
}
