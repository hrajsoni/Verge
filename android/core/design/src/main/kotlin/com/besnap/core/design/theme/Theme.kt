package com.besnap.core.design.theme

import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.runtime.Composable

private val DarkColorScheme = darkColorScheme(
    primary = Purple40,
    onPrimary = androidx.compose.ui.graphics.Color.White,
    primaryContainer = Purple20,
    secondary = Pink40,
    onSecondary = androidx.compose.ui.graphics.Color.White,
    background = DarkSurface,
    surface = DarkSurfaceVariant,
    surfaceVariant = DarkSurfaceHigh,
    onBackground = androidx.compose.ui.graphics.Color.White,
    onSurface = androidx.compose.ui.graphics.Color.White,
)

@Composable
fun BeSnapTheme(
    content: @Composable () -> Unit
) {
    MaterialTheme(
        colorScheme = DarkColorScheme,
        typography = BeSnapTypography,
        content = content
    )
}
