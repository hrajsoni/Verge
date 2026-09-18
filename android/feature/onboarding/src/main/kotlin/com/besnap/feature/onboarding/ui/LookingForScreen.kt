package com.besnap.feature.onboarding.ui

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.besnap.core.design.components.BeSnapButton
import com.besnap.feature.onboarding.model.LookingFor

@Composable
fun LookingForScreen(
    selectedOption: LookingFor,
    onOptionSelected: (LookingFor) -> Unit,
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
            text = "What are you looking for?",
            style = MaterialTheme.typography.headlineLarge
        )
        
        Spacer(modifier = Modifier.height(32.dp))
        
        val options = listOf(
            LookingFor.FRIENDS to "Friends",
            LookingFor.DATING to "Dating",
            LookingFor.FRIENDS_AND_DATING to "Friends + Dating"
        )
        
        options.forEach { (option, label) ->
            Card(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(vertical = 8.dp)
                    .clickable { onOptionSelected(option) },
                colors = CardDefaults.cardColors(
                    containerColor = if (selectedOption == option) MaterialTheme.colorScheme.primaryContainer else MaterialTheme.colorScheme.surfaceVariant
                )
            ) {
                Text(
                    text = label,
                    modifier = Modifier.padding(16.dp),
                    style = MaterialTheme.typography.titleMedium,
                    color = if (selectedOption == option) MaterialTheme.colorScheme.onPrimaryContainer else MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        }
        
        Spacer(modifier = Modifier.weight(1f))
        
        BeSnapButton(
            text = "Continue",
            onClick = onNext,
            modifier = Modifier.fillMaxWidth()
        )
        
        Spacer(modifier = Modifier.height(32.dp))
    }
}
