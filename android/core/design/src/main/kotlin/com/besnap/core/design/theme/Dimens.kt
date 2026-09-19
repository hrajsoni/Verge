package com.besnap.core.design.theme

import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp

data class BeSnapDimens(
    val spacingXXS: Dp = 2.dp,
    val spacingXS: Dp = 4.dp,
    val spacingS: Dp = 8.dp,
    val spacingM: Dp = 12.dp,
    val spacingL: Dp = 16.dp,
    val spacingXL: Dp = 20.dp,
    val spacingXXL: Dp = 24.dp,
    val spacingXXXL: Dp = 32.dp,
    val spacingHuge: Dp = 40.dp,
    val spacingMassive: Dp = 48.dp,
    
    // Icon sizes
    val iconSmall: Dp = 16.dp,
    val iconMedium: Dp = 24.dp,
    val iconLarge: Dp = 32.dp,
    
    // Avatar sizes
    val avatarSmall: Dp = 36.dp,
    val avatarMedium: Dp = 48.dp,
    val avatarLarge: Dp = 64.dp,
    val avatarXLarge: Dp = 96.dp,
    
    // Button heights
    val buttonHeight: Dp = 52.dp,
    val buttonHeightSmall: Dp = 40.dp,
)

val LocalBeSnapDimens = staticCompositionLocalOf { BeSnapDimens() }
