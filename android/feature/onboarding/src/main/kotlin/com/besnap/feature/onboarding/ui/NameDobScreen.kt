package com.besnap.feature.onboarding.ui

import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.besnap.core.design.components.BeSnapButton

@Composable
fun NameDobScreen(
    displayName: String,
    dob: String,
    onNameChange: (String) -> Unit,
    onDobChange: (String) -> Unit,
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
            text = "Tell us about yourself",
            style = MaterialTheme.typography.headlineLarge
        )
        
        Spacer(modifier = Modifier.height(32.dp))
        
        OutlinedTextField(
            value = displayName,
            onValueChange = onNameChange,
            label = { Text("Display Name") },
            modifier = Modifier.fillMaxWidth()
        )
        
        Spacer(modifier = Modifier.height(16.dp))
        
        OutlinedTextField(
            value = dob,
            onValueChange = onDobChange,
            label = { Text("Date of Birth (YYYY-MM-DD)") },
            modifier = Modifier.fillMaxWidth()
        )
        
        Text(
            text = "You must be 18 or older to use Be-Snap.",
            style = MaterialTheme.typography.bodySmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            modifier = Modifier.padding(top = 8.dp)
        )
        
        Spacer(modifier = Modifier.weight(1f))
        
        BeSnapButton(
            text = "Continue",
            onClick = onNext,
            enabled = displayName.isNotBlank() && dob.isNotBlank(),
            modifier = Modifier.fillMaxWidth()
        )
        
        Spacer(modifier = Modifier.height(32.dp))
    }
}
