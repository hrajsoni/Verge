package com.besnap.core.design.theme

import androidx.compose.animation.core.CubicBezierEasing
import androidx.compose.animation.core.Easing
import androidx.compose.animation.core.FastOutSlowInEasing
import androidx.compose.animation.core.Spring
import androidx.compose.animation.core.spring
import androidx.compose.animation.core.tween

object BeSnapMotion {
    const val DurationFast = 150
    const val DurationNormal = 250
    const val DurationEmphasis = 400

    val StandardEasing: Easing = FastOutSlowInEasing
    val EmphasizedEasing: Easing = CubicBezierEasing(0.2f, 0.0f, 0.0f, 1.0f)

    fun <T> fastTween() = tween<T>(durationMillis = DurationFast, easing = StandardEasing)
    fun <T> normalTween() = tween<T>(durationMillis = DurationNormal, easing = StandardEasing)
    fun <T> emphasisTween() = tween<T>(durationMillis = DurationEmphasis, easing = EmphasizedEasing)
    
    fun <T> gentleSpring() = spring<T>(
        dampingRatio = Spring.DampingRatioMediumBouncy,
        stiffness = Spring.StiffnessLow
    )
}
