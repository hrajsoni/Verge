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
import com.besnap.feature.matches.MatchesUiState
import com.besnap.feature.matches.MatchesViewModel
import com.besnap.feature.matches.model.MatchItem

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
        modifier = modifier
    )
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun MatchesScreen(
    uiState: MatchesUiState,
    onNavigateToChat: (String) -> Unit,
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
        if (uiState.isLoading) {
            Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                CircularProgressIndicator()
            }
        } else {
            LazyColumn(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(padding)
            ) {
                if (uiState.newMatches.isNotEmpty()) {
                    item {
                        Text(
                            text = "💜 New Matches",
                            style = MaterialTheme.typography.titleMedium,
                            fontWeight = FontWeight.Bold,
                            modifier = Modifier.padding(horizontal = 16.dp, vertical = 8.dp)
                        )
                        LazyRow(
                            contentPadding = PaddingValues(horizontal = 16.dp),
                            horizontalArrangement = Arrangement.spacedBy(12.dp)
                        ) {
                            items(uiState.newMatches, key = { it.matchId }) { match ->
                                NewMatchItem(match = match, onClick = {
                                    match.conversationId?.let { onNavigateToChat(it) }
                                })
                            }
                        }
                        Spacer(modifier = Modifier.height(16.dp))
                    }
                }

                item {
                    Text(
                        text = "Your Connections",
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Bold,
                        modifier = Modifier.padding(horizontal = 16.dp, vertical = 8.dp)
                    )
                }

                items(uiState.connections, key = { it.matchId }) { connection ->
                    ConnectionItem(
                        match = connection,
                        onClick = {
                            connection.conversationId?.let { onNavigateToChat(it) }
                        }
                    )
                }
            }
        }
    }
}

@Composable
fun NewMatchItem(
    match: MatchItem,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        modifier = modifier.clickable(onClick = onClick)
    ) {
        AsyncImage(
            model = match.photoUrl,
            contentDescription = "Avatar of ${match.displayName}",
            contentScale = ContentScale.Crop,
            modifier = Modifier
                .size(72.dp)
                .clip(CircleShape)
        )
        Spacer(modifier = Modifier.height(4.dp))
        Text(
            text = match.displayName,
            style = MaterialTheme.typography.bodyMedium
        )
    }
}

@Composable
fun ConnectionItem(
    match: MatchItem,
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
            model = match.photoUrl,
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
                fontWeight = if (match.unreadCount > 0) FontWeight.Bold else FontWeight.Normal
            )
            Spacer(modifier = Modifier.height(4.dp))
            Text(
                text = match.lastMessage ?: "",
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
                fontWeight = if (match.unreadCount > 0) FontWeight.Bold else FontWeight.Normal
            )
        }
        if (match.unreadCount > 0) {
            Badge(
                containerColor = MaterialTheme.colorScheme.primary,
                contentColor = MaterialTheme.colorScheme.onPrimary
            ) {
                Text(match.unreadCount.toString())
            }
        }
    }
}
