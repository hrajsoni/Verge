package com.besnap.core.design.theme

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.ui.graphics.Color

private val DarkColorScheme = darkColorScheme(
    primary = Purple40,
    onPrimary = Color.White,
    primaryContainer = Purple20,
    secondary = Pink40,
    onSecondary = Color.White,
    background = DarkSurface,
    surface = DarkSurfaceVariant,
    surfaceVariant = DarkSurfaceHigh,
    onBackground = Color.White,
    onSurface = Color.White,
    outline = DarkOutline,
    outlineVariant = DarkOutlineVariant,
    error = ErrorRedDark,
    onError = Color.Black,
)

private val LightColorScheme = lightColorScheme(
    primary = Purple40,
    onPrimary = Color.White,
    primaryContainer = Purple80,
    secondary = Pink40,
    onSecondary = Color.White,
    background = LightBackground,
    surface = LightSurface,
    surfaceVariant = LightSurfaceVariant,
    onBackground = LightOnSurface,
    onSurface = LightOnSurface,
    outline = LightOutline,
    outlineVariant = LightOutlineVariant,
    error = ErrorRed,
    onError = Color.White,
)

@Composable
fun BeSnapTheme(
    darkTheme: Boolean = isSystemInDarkTheme(),
    dimens: BeSnapDimens = BeSnapDimens(),
    content: @Composable () -> Unit
) {
    val colorScheme = if (darkTheme) DarkColorScheme else LightColorScheme

    CompositionLocalProvider(
        LocalBeSnapDimens provides dimens
    ) {
        MaterialTheme(
            colorScheme = colorScheme,
            typography = BeSnapTypography,
            shapes = BeSnapShapes,
            content = content
        )
    }
}
