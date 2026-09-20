package com.besnap.feature.matches.ui

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import coil.compose.AsyncImage
import com.besnap.core.design.components.BeSnapEmptyState
import com.besnap.core.design.components.BeSnapErrorState
import com.besnap.core.design.components.BeSnapLoadingIndicator
import com.besnap.core.network.model.MatchDto
import com.besnap.feature.matches.MatchesUiState
import com.besnap.feature.matches.MatchesViewModel

@Composable
fun MatchesRoute(
    onNavigateToChat: (String) -> Unit,
    modifier: Modifier = Modifier,
    viewModel: MatchesViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()
    MatchesScreen(
        uiState = uiState,
        onNavigateToChat = onNavigateToChat,
        onRetry = viewModel::loadMatches,
        modifier = modifier
    )
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun MatchesScreen(
    uiState: MatchesUiState,
    onNavigateToChat: (String) -> Unit,
    onRetry: () -> Unit,
    modifier: Modifier = Modifier
) {
    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Matches & Messages") }
            )
        },
        modifier = modifier
    ) { padding ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
        ) {
            when (uiState) {
                is MatchesUiState.Loading -> {
                    BeSnapLoadingIndicator(modifier = Modifier.align(Alignment.Center))
                }
                is MatchesUiState.Empty -> {
                    BeSnapEmptyState(
                        title = "No matches yet",
                        subtitle = "Keep swiping to find people nearby",
                        modifier = Modifier.align(Alignment.Center)
                    )
                }
                is MatchesUiState.Error -> {
                    BeSnapErrorState(
                        message = uiState.message,
                        onRetry = onRetry,
                        modifier = Modifier.align(Alignment.Center)
                    )
                }
                is MatchesUiState.Success -> {
                    LazyColumn(
                        modifier = Modifier.fillMaxSize()
                    ) {
                        item {
                            Text(
                                text = "Your Matches",
                                style = MaterialTheme.typography.titleMedium,
                                fontWeight = FontWeight.Bold,
                                modifier = Modifier.padding(horizontal = 16.dp, vertical = 8.dp)
                            )
                        }

                        items(uiState.matches, key = { it.id }) { match ->
                            ConnectionItem(
                                match = match,
                                onClick = {
                                    match.conversationId?.let { onNavigateToChat(it) }
                                }
                            )
                        }
                    }
                }
            }
        }
    }
}

@Composable
fun ConnectionItem(
    match: MatchDto,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    Row(
        modifier = modifier
            .fillMaxWidth()
            .clickable(onClick = onClick)
            .padding(horizontal = 16.dp, vertical = 12.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        AsyncImage(
            model = match.avatarUrl,
            contentDescription = "Avatar of ${match.displayName}",
            contentScale = ContentScale.Crop,
            modifier = Modifier
                .size(56.dp)
                .clip(CircleShape)
        )
        Spacer(modifier = Modifier.width(16.dp))
        Column(modifier = Modifier.weight(1f)) {
            Text(
                text = match.displayName,
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Normal
            )
            Spacer(modifier = Modifier.height(4.dp))
            Text(
                text = "Matched on ${match.matchedAt.take(10)}",
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis
            )
        }
    }
}
