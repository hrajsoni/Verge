package com.besnap.feature.chat.ui

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.background
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material.icons.filled.Call
import androidx.compose.material.icons.filled.CameraAlt
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Mic
import androidx.compose.material.icons.filled.Send
import androidx.compose.material.icons.filled.Videocam
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import coil.compose.AsyncImage
import com.besnap.feature.chat.ChatUiState
import com.besnap.feature.chat.ChatViewModel

@Composable
fun ChatRoute(
    onBackClick: () -> Unit,
    modifier: Modifier = Modifier,
    viewModel: ChatViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()
    val activeSnaps by viewModel.activeSnaps.collectAsState()
    ChatScreen(
        uiState = uiState,
        activeSnaps = activeSnaps,
        onBackClick = onBackClick,
        onTextChanged = viewModel::onTextChanged,
        onSendMessage = viewModel::sendMessage,
        onSendSnap = viewModel::sendSnap,
        onSnapTap = viewModel::openSnap,
        onSnapReplay = viewModel::openSnap,
        onSnapClose = viewModel::markSnapViewed,
        modifier = modifier
    )
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ChatScreen(
    uiState: ChatUiState,
    activeSnaps: Map<String, com.besnap.core.network.model.OpenSnapResponse>,
    onBackClick: () -> Unit,
    onTextChanged: (String) -> Unit,
    onSendMessage: () -> Unit,
    onSendSnap: () -> Unit,
    onSnapTap: (String) -> Unit,
    onSnapReplay: (String) -> Unit,
    onSnapClose: (String) -> Unit,
    modifier: Modifier = Modifier
) {
    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        AsyncImage(
                            model = null, // other user photo url
                            contentDescription = null,
                            contentScale = ContentScale.Crop,
                            modifier = Modifier
                                .size(36.dp)
                                .clip(CircleShape)
                        )
                        Spacer(modifier = Modifier.width(12.dp))
                        Column {
                            Text("Other User", style = MaterialTheme.typography.titleMedium)
                            Text(
                                if (uiState.isOtherTyping) "Typing..." else "Online",
                                style = MaterialTheme.typography.bodySmall,
                                color = MaterialTheme.colorScheme.primary
                            )
                        }
                    }
                },
                navigationIcon = {
                    IconButton(onClick = onBackClick) {
                        Icon(Icons.Default.ArrowBack, contentDescription = "Back")
                    }
                },
                actions = {
                    IconButton(onClick = { /* call */ }) {
                        Icon(Icons.Default.Call, contentDescription = "Call")
                    }
                    IconButton(onClick = { /* video */ }) {
                        Icon(Icons.Default.Videocam, contentDescription = "Video Call")
                    }
                }
            )
        },
        bottomBar = {
            ChatInputBar(
                inputText = uiState.inputText,
                onTextChanged = onTextChanged,
                onSendMessage = onSendMessage,
                onCameraClick = onSendSnap,
                onMicClick = { /* voice */ }
            )
        },
        modifier = modifier
    ) { padding ->
        LazyColumn(
            reverseLayout = true,
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .padding(horizontal = 16.dp),
            contentPadding = PaddingValues(vertical = 16.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            items(uiState.messages, key = { it.id }) { message ->
                ChatBubble(
                    message = message,
                    onSnapTap = onSnapTap,
                    onSnapReplay = onSnapReplay
                )
            }
        }
        
        // Active snaps overlay
        activeSnaps.forEach { (messageId, snap) ->
            SnapViewOverlay(
                snap = snap,
                onClose = { onSnapClose(messageId) }
            )
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ChatInputBar(
    inputText: String,
    onTextChanged: (String) -> Unit,
    onSendMessage: () -> Unit,
    onCameraClick: () -> Unit,
    onMicClick: () -> Unit
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(8.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        IconButton(onClick = onCameraClick) {
            Icon(Icons.Default.CameraAlt, contentDescription = "Camera", tint = MaterialTheme.colorScheme.primary)
        }
        OutlinedTextField(
            value = inputText,
            onValueChange = onTextChanged,
            modifier = Modifier.weight(1f),
            placeholder = { Text("Message...") },
            shape = MaterialTheme.shapes.extraLarge,
            colors = OutlinedTextFieldDefaults.colors(
                unfocusedBorderColor = MaterialTheme.colorScheme.surfaceVariant,
                unfocusedContainerColor = MaterialTheme.colorScheme.surfaceVariant,
                focusedContainerColor = MaterialTheme.colorScheme.surfaceVariant
            )
        )
        if (inputText.isNotBlank()) {
            IconButton(onClick = onSendMessage) {
                Icon(Icons.Default.Send, contentDescription = "Send", tint = MaterialTheme.colorScheme.primary)
            }
        } else {
            IconButton(onClick = onMicClick) {
                Icon(Icons.Default.Mic, contentDescription = "Microphone", tint = MaterialTheme.colorScheme.onSurfaceVariant)
            }
        }
    }
}

@Composable
fun SnapViewOverlay(
    snap: com.besnap.core.network.model.OpenSnapResponse,
    onClose: () -> Unit
) {
    var timeLeft by remember { mutableStateOf(snap.viewDurationSeconds) }
    
    LaunchedEffect(snap.viewDurationSeconds) {
        while(timeLeft > 0) {
            kotlinx.coroutines.delay(1000)
            timeLeft--
        }
        onClose()
    }

    androidx.compose.ui.window.Dialog(
        onDismissRequest = onClose,
        properties = androidx.compose.ui.window.DialogProperties(usePlatformDefaultWidth = false)
    ) {
        Box(modifier = Modifier.fillMaxSize().background(androidx.compose.ui.graphics.Color.Black)) {
            AsyncImage(
                model = snap.viewUrl,
                contentDescription = "Snap",
                modifier = Modifier.fillMaxSize(),
                contentScale = ContentScale.Fit
            )
            
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(16.dp)
                    .align(Alignment.TopCenter),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                IconButton(onClick = onClose) {
                    Icon(
                        Icons.Default.Close,
                        contentDescription = "Close",
                        tint = androidx.compose.ui.graphics.Color.White
                    )
                }
                Text(
                    text = "${timeLeft}s",
                    color = androidx.compose.ui.graphics.Color.White,
                    style = MaterialTheme.typography.titleLarge
                )
            }
        }
    }
}
