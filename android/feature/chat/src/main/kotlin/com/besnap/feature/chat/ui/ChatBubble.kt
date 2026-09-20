package com.besnap.feature.chat.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CameraAlt
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import com.besnap.feature.chat.model.ChatMessage
import com.besnap.feature.chat.model.ChatMessageType
import com.besnap.feature.chat.model.SnapViewState
import java.time.format.DateTimeFormatter

@Composable
fun ChatBubble(
    message: ChatMessage,
    modifier: Modifier = Modifier
) {
    val isMine = message.isMine
    val bubbleShape = if (isMine) {
        RoundedCornerShape(16.dp, 16.dp, 4.dp, 16.dp)
    } else {
        RoundedCornerShape(16.dp, 16.dp, 16.dp, 4.dp)
    }

    val bubbleColor = if (isMine) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.surfaceVariant
    val textColor = if (isMine) MaterialTheme.colorScheme.onPrimary else MaterialTheme.colorScheme.onSurfaceVariant

    Row(
        modifier = modifier.fillMaxWidth(),
        horizontalArrangement = if (isMine) Arrangement.End else Arrangement.Start
    ) {
        Box(
            modifier = Modifier
                .widthIn(max = 280.dp)
                .background(bubbleColor, bubbleShape)
                .padding(12.dp)
        ) {
            Column {
                if (message.type == ChatMessageType.SNAP) {
                    SnapContent(message, textColor)
                } else {
                    message.text?.let {
                        Text(text = it, color = textColor, style = MaterialTheme.typography.bodyLarge)
                    }
                }
                Spacer(modifier = Modifier.height(4.dp))
                val formatter = remember { DateTimeFormatter.ofPattern("HH:mm") }
                Text(
                    text = message.timestamp.format(formatter),
                    color = textColor.copy(alpha = 0.7f),
                    style = MaterialTheme.typography.labelSmall,
                    modifier = Modifier.align(Alignment.End)
                )
            }
        }
    }
}

@Composable
fun SnapContent(message: ChatMessage, textColor: Color) {
    Row(verticalAlignment = Alignment.CenterVertically) {
        val iconTint = if (message.snapViewState == SnapViewState.UNOPENED) Color.Red else textColor
        Icon(Icons.Default.CameraAlt, contentDescription = "Snap", tint = iconTint)
        Spacer(modifier = Modifier.width(8.dp))
        val text = when (message.snapViewState) {
            SnapViewState.UNOPENED -> "Tap to view"
            SnapViewState.OPENED -> "Opened"
            else -> "Expired"
        }
        Text(text = text, color = textColor, style = MaterialTheme.typography.bodyLarge)
    }
}
