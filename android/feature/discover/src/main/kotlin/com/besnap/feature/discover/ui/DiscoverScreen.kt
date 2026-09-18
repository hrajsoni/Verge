package com.besnap.feature.discover.ui

import androidx.compose.foundation.border
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import com.besnap.core.design.theme.LikeGreen
import com.besnap.core.design.theme.PassRed

@Composable
fun DiscoverRoute(
    viewModel: DiscoverViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()

    DiscoverScreen(
        uiState = uiState,
        onSwipeLeft = viewModel::onSwipeLeft,
        onSwipeRight = viewModel::onSwipeRight,
        onLikeClicked = viewModel::onLikeClicked,
        onPassClicked = viewModel::onPassClicked,
        onRefresh = viewModel::refresh,
        onMatchEventConsumed = viewModel::consumeMatchEvent
    )
}

@Composable
fun DiscoverScreen(
    uiState: DiscoverUiState,
    onSwipeLeft: () -> Unit,
    onSwipeRight: () -> Unit,
    onLikeClicked: () -> Unit,
    onPassClicked: () -> Unit,
    onRefresh: () -> Unit,
    onMatchEventConsumed: () -> Unit
) {
    Box(modifier = Modifier.fillMaxSize()) {
        when {
            uiState.isLoading -> {
                CircularProgressIndicator(
                    modifier = Modifier.align(Alignment.Center)
                )
            }
            uiState.error != null -> {
                Column(
                    modifier = Modifier.align(Alignment.Center),
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.spacedBy(16.dp)
                ) {
                    Text(text = uiState.error, color = MaterialTheme.colorScheme.error)
                    Button(onClick = onRefresh) {
                        Text("Retry")
                    }
                }
            }
            uiState.currentIndex >= uiState.cards.size -> {
                Column(
                    modifier = Modifier
                        .align(Alignment.Center)
                        .padding(32.dp),
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.spacedBy(16.dp)
                ) {
                    Text(
                        text = "No more people nearby! Expand your distance or check back later.",
                        textAlign = TextAlign.Center,
                        style = MaterialTheme.typography.bodyLarge
                    )
                    Button(onClick = onRefresh) {
                        Text("Refresh")
                    }
                }
            }
            else -> {
                val currentCard = uiState.cards[uiState.currentIndex]
                
                // Show next card behind
                if (uiState.currentIndex + 1 < uiState.cards.size) {
                    val nextCard = uiState.cards[uiState.currentIndex + 1]
                    ProfileCard(
                        card = nextCard,
                        onPassClick = {},
                        onLikeClick = {},
                        modifier = Modifier
                            .fillMaxSize()
                            .padding(16.dp)
                    )
                }

                // Current card
                key(currentCard.userId) {
                    SwipeableCard(
                        onSwipedLeft = onSwipeLeft,
                        onSwipedRight = onSwipeRight,
                        modifier = Modifier
                            .fillMaxSize()
                            .padding(16.dp)
                    ) { dragOffset ->
                        Box(modifier = Modifier.fillMaxSize()) {
                            ProfileCard(
                                card = currentCard,
                                onPassClick = onPassClicked,
                                onLikeClick = onLikeClicked
                            )

                            // Stamp Overlays
                            if (dragOffset > 50f) {
                                StampOverlay(
                                    text = "LIKE",
                                    color = LikeGreen,
                                    modifier = Modifier
                                        .align(Alignment.TopStart)
                                        .padding(start = 32.dp, top = 64.dp)
                                        .alpha((dragOffset / 300f).coerceIn(0f, 1f))
                                )
                            } else if (dragOffset < -50f) {
                                StampOverlay(
                                    text = "PASS",
                                    color = PassRed,
                                    modifier = Modifier
                                        .align(Alignment.TopEnd)
                                        .padding(end = 32.dp, top = 64.dp)
                                        .alpha((-dragOffset / 300f).coerceIn(0f, 1f))
                                )
                            }
                        }
                    }
                }
            }
        }

        uiState.matchEvent?.let { message ->
            AlertDialog(
                onDismissRequest = onMatchEventConsumed,
                title = { Text("It's a Match!") },
                text = { Text(message) },
                confirmButton = {
                    Button(onClick = onMatchEventConsumed) {
                        Text("Awesome")
                    }
                }
            )
        }
    }
}

@Composable
fun StampOverlay(
    text: String,
    color: Color,
    modifier: Modifier = Modifier
) {
    Box(
        modifier = modifier
            .border(
                width = 4.dp,
                color = color,
                shape = RoundedCornerShape(12.dp)
            )
            .padding(horizontal = 16.dp, vertical = 8.dp)
    ) {
        Text(
            text = text,
            color = color,
            fontSize = 32.sp,
            fontWeight = FontWeight.Bold,
            letterSpacing = 4.sp
        )
    }
}
