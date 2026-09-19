package com.besnap.feature.onboarding.ui

import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.besnap.core.design.components.BeSnapButton
import com.besnap.core.design.components.InterestChip

val availableInterests = listOf(
    "🎵" to "Music", "🎮" to "Gaming", "🏋️" to "Fitness", "📷" to "Photography",
    "💻" to "Technology", "🎬" to "Movies", "✈️" to "Travel", "⚽" to "Sports",
    "🍜" to "Food", "📚" to "Reading", "🎨" to "Art", "💃" to "Dancing"
)

@OptIn(ExperimentalLayoutApi::class)
@Composable
fun InterestsScreen(
    selectedInterests: Set<String>,
    onToggleInterest: (String) -> Unit,
    onNext: () -> Unit,
    onBack: () -> Unit,
    modifier: Modifier = Modifier
) {
    Column(
        modifier = modifier
            .fillMaxSize()
            .padding(24.dp)
    ) {
        TextButton(onClick = onBack) {
            Text("Back")
        }
        
        Spacer(modifier = Modifier.height(16.dp))
        
        Text(
            text = "Your Interests",
            style = MaterialTheme.typography.headlineLarge
        )
        Text(
            text = "Select at least 3 interests to help us match you.",
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
        
        Spacer(modifier = Modifier.height(32.dp))
        
        FlowRow(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(8.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            availableInterests.forEach { (emoji, label) ->
                InterestChip(
                    emoji = emoji,
                    label = label,
                    selected = selectedInterests.contains(label),
                    onClick = { onToggleInterest(label) }
                )
            }
        }
        
        Spacer(modifier = Modifier.weight(1f))
        
        Text(
            text = "${selectedInterests.size}/3 Selected",
            style = MaterialTheme.typography.bodyMedium,
            modifier = Modifier.padding(bottom = 16.dp)
        )
        
        BeSnapButton(
            text = "Continue",
            onClick = onNext,
            enabled = selectedInterests.size >= 3,
            modifier = Modifier.fillMaxWidth()
        )
        
        Spacer(modifier = Modifier.height(32.dp))
    }
}
