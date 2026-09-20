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
        when (uiState) {
            is DiscoverUiState.Loading -> {
                CircularProgressIndicator(
                    modifier = Modifier.align(Alignment.Center)
                )
            }
            is DiscoverUiState.Error -> {
                Column(
                    modifier = Modifier.align(Alignment.Center),
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.spacedBy(16.dp)
                ) {
                    Text(text = uiState.message, color = MaterialTheme.colorScheme.error)
                    Button(onClick = onRefresh) {
                        Text("Retry")
                    }
                }
            }
            is DiscoverUiState.Empty -> {
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
            is DiscoverUiState.Success -> {
                val currentCard = uiState.cards.getOrNull(uiState.currentIndex)
                
                if (currentCard == null) {
                    // Should be handled by Empty state, but fallback just in case
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
                } else {
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
                        ) {
                            Box(modifier = Modifier.fillMaxSize()) {
                                ProfileCard(
                                    card = currentCard,
                                    onPassClick = onPassClicked,
                                    onLikeClick = onLikeClicked
                                )
                                // Removed Stamp Overlays since dragOffset is no longer available
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
        }
    }
}
