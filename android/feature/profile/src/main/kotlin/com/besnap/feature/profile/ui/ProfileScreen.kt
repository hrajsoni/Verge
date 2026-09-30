package com.besnap.feature.profile.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Edit
import androidx.compose.material.icons.filled.Person
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import coil.compose.AsyncImage
import com.besnap.core.design.components.BeSnapEmptyState
import com.besnap.core.design.components.BeSnapErrorState
import com.besnap.core.design.components.BeSnapLoadingIndicator
import com.besnap.core.design.components.BeSnapTopBar
import com.besnap.feature.profile.ProfileUiState
import com.besnap.feature.profile.ProfileViewModel

@Composable
fun ProfileScreen(
    modifier: Modifier = Modifier,
    viewModel: ProfileViewModel = hiltViewModel(),
) {
    val uiState by viewModel.uiState.collectAsState()
    val displayName by viewModel.editDisplayName.collectAsState()
    val bio by viewModel.editBio.collectAsState()

    Scaffold(
        topBar = {
            BeSnapTopBar(
                title = "My Profile",
                actions = {
                    if (uiState is ProfileUiState.Success) {
                        val successState = uiState as ProfileUiState.Success
                        if (!successState.isEditing) {
                            IconButton(onClick = viewModel::startEditing) {
                                Icon(Icons.Default.Edit, contentDescription = "Edit Profile")
                            }
                        }
                    }
                }
            )
        },
        modifier = modifier,
    ) { padding ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding),
        ) {
            when (val state = uiState) {
                is ProfileUiState.Loading -> BeSnapLoadingIndicator(modifier = Modifier.align(Alignment.Center))
                is ProfileUiState.Error -> BeSnapErrorState(
                    message = state.message,
                    onRetry = viewModel::loadProfile,
                    modifier = Modifier.align(Alignment.Center),
                )
                is ProfileUiState.Success -> {
                    if (state.isEditing) {
                        EditProfileContent(
                            displayName = displayName,
                            bio = bio,
                            onDisplayNameChange = { viewModel.editDisplayName.value = it },
                            onBioChange = { viewModel.editBio.value = it },
                            onSave = viewModel::saveProfile,
                            onCancel = viewModel::cancelEditing,
                        )
                    } else {
                        ViewProfileContent(profile = state.profile)
                    }
                }
            }
        }
    }
}

@Composable
private fun ViewProfileContent(profile: com.besnap.core.network.model.ProfileResponse) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
            .padding(horizontal = 24.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Spacer(modifier = Modifier.height(32.dp))
        // Avatar
        Box(
            modifier = Modifier
                .size(100.dp)
                .clip(CircleShape)
                .background(MaterialTheme.colorScheme.surfaceVariant)
                .border(2.dp, MaterialTheme.colorScheme.primary, CircleShape),
            contentAlignment = Alignment.Center,
        ) {
            if (profile.photoUrl != null) {
                AsyncImage(
                    model = profile.photoUrl,
                    contentDescription = "Avatar",
                    modifier = Modifier.fillMaxSize(),
                    contentScale = ContentScale.Crop,
                )
            } else {
                Icon(
                    imageVector = Icons.Default.Person,
                    contentDescription = null,
                    modifier = Modifier.size(48.dp),
                    tint = MaterialTheme.colorScheme.onSurfaceVariant,
                )
            }
        }

        Spacer(modifier = Modifier.height(16.dp))

        // Display name
        Text(
            text = profile.displayName,
            style = MaterialTheme.typography.headlineSmall,
            fontWeight = FontWeight.Bold,
            textAlign = TextAlign.Center,
        )

        // Age + gender
        val ageGender = listOfNotNull(
            profile.age?.let { "${it}y" },
            profile.gender,
        ).joinToString(" · ")
        if (ageGender.isNotEmpty()) {
            Spacer(modifier = Modifier.height(4.dp))
            Text(
                text = ageGender,
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                textAlign = TextAlign.Center,
            )
        }

        // Bio
        val bio = profile.bio
        if (!bio.isNullOrBlank()) {
            Spacer(modifier = Modifier.height(16.dp))
            Card(
                modifier = Modifier.fillMaxWidth(),
                colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant),
            ) {
                Text(
                    text = bio,
                    style = MaterialTheme.typography.bodyMedium,
                    modifier = Modifier.padding(16.dp),
                )
            }
        }

        Spacer(modifier = Modifier.height(32.dp))
    }
}

@Composable
private fun EditProfileContent(
    displayName: String,
    bio: String,
    onDisplayNameChange: (String) -> Unit,
    onBioChange: (String) -> Unit,
    onSave: () -> Unit,
    onCancel: () -> Unit,
) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
            .padding(24.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp),
    ) {
        OutlinedTextField(
            value = displayName,
            onValueChange = onDisplayNameChange,
            label = { Text("Display Name") },
            singleLine = true,
            modifier = Modifier.fillMaxWidth(),
        )
        OutlinedTextField(
            value = bio,
            onValueChange = onBioChange,
            label = { Text("Bio") },
            minLines = 3,
            maxLines = 6,
            modifier = Modifier.fillMaxWidth(),
        )
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            OutlinedButton(
                onClick = onCancel,
                modifier = Modifier.weight(1f),
            ) { Text("Cancel") }
            Button(
                onClick = onSave,
                modifier = Modifier.weight(1f),
            ) { Text("Save") }
        }
    }
}
