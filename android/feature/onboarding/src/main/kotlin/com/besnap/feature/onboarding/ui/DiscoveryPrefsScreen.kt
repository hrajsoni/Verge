package com.besnap.feature.onboarding.ui

import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.besnap.core.design.components.BeSnapButton
import com.besnap.feature.onboarding.model.Gender

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun DiscoveryPrefsScreen(
    minAge: Int,
    maxAge: Int,
    maxDistanceKm: Int,
    interestedInGenders: Set<Gender>,
    onPreferencesChanged: (Int, Int, Int, Set<Gender>) -> Unit,
    onNext: () -> Unit,
    onBack: () -> Unit,
    modifier: Modifier = Modifier
) {
    var localMinAge by remember { mutableStateOf(minAge.toFloat()) }
    var localMaxAge by remember { mutableStateOf(maxAge.toFloat()) }
    var localDistance by remember { mutableStateOf(maxDistanceKm.toFloat()) }
    var localGenders by remember { mutableStateOf(interestedInGenders) }

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
            text = "Discovery Preferences",
            style = MaterialTheme.typography.headlineLarge
        )
        
        Spacer(modifier = Modifier.height(32.dp))
        
        Text("Age Range: ${localMinAge.toInt()} - ${localMaxAge.toInt()}", style = MaterialTheme.typography.titleMedium)
        RangeSlider(
            value = localMinAge..localMaxAge,
            onValueChange = { range ->
                localMinAge = range.start
                localMaxAge = range.endInclusive
                onPreferencesChanged(localMinAge.toInt(), localMaxAge.toInt(), localDistance.toInt(), localGenders)
            },
            valueRange = 18f..100f,
            steps = 82
        )
        
        Spacer(modifier = Modifier.height(24.dp))
        
        Text("Maximum Distance: ${localDistance.toInt()} km", style = MaterialTheme.typography.titleMedium)
        Slider(
            value = localDistance,
            onValueChange = {
                localDistance = it
                onPreferencesChanged(localMinAge.toInt(), localMaxAge.toInt(), localDistance.toInt(), localGenders)
            },
            valueRange = 1f..100f,
            steps = 99
        )
        
        Spacer(modifier = Modifier.height(24.dp))
        
        Text("Interested In", style = MaterialTheme.typography.titleMedium)
        Gender.entries.forEach { gender ->
            Row(
                verticalAlignment = Alignment.CenterVertically,
                modifier = Modifier.fillMaxWidth()
            ) {
                Checkbox(
                    checked = localGenders.contains(gender),
                    onCheckedChange = { checked ->
                        val newGenders = localGenders.toMutableSet()
                        if (checked) newGenders.add(gender) else newGenders.remove(gender)
                        localGenders = newGenders
                        onPreferencesChanged(localMinAge.toInt(), localMaxAge.toInt(), localDistance.toInt(), localGenders)
                    }
                )
                Text(gender.name.lowercase().replaceFirstChar { it.uppercase() })
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
