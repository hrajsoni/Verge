package com.besnap.feature.discover.ui

import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.tween
import androidx.compose.foundation.gestures.detectDragGestures
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.offset
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.unit.IntOffset
import androidx.compose.ui.unit.dp
import kotlinx.coroutines.launch
import kotlin.math.abs
import kotlin.math.roundToInt

@Composable
fun SwipeableCard(
    onSwipedLeft: () -> Unit,
    onSwipedRight: () -> Unit,
    modifier: Modifier = Modifier,
    content: @Composable (dragOffset: Float) -> Unit
) {
    val screenWidth = with(LocalDensity.current) { LocalConfiguration.current.screenWidthDp.dp.toPx() }
    val swipeThreshold = screenWidth * 0.3f
    
    val offsetX = remember { Animatable(0f) }
    val offsetY = remember { Animatable(0f) }
    val coroutineScope = rememberCoroutineScope()

    Box(
        modifier = modifier
            .offset { IntOffset(offsetX.value.roundToInt(), offsetY.value.roundToInt()) }
            .graphicsLayer {
                val progress = (offsetX.value / screenWidth).coerceIn(-1f, 1f)
                rotationZ = progress * 15f // Max 15 degrees rotation
            }
            .pointerInput(Unit) {
                detectDragGestures(
                    onDragEnd = {
                        coroutineScope.launch {
                            val targetX = offsetX.value
                            if (abs(targetX) > swipeThreshold) {
                                // Animate off screen
                                val finalX = if (targetX > 0) screenWidth * 1.5f else -screenWidth * 1.5f
                                offsetX.animateTo(finalX, tween(300))
                                
                                if (targetX > 0) {
                                    onSwipedRight()
                                } else {
                                    onSwipedLeft()
                                }
                            } else {
                                // Snap back
                                offsetX.animateTo(0f, tween(300))
                                offsetY.animateTo(0f, tween(300))
                            }
                        }
                    },
                    onDrag = { change, dragAmount ->
                        change.consume()
                        coroutineScope.launch {
                            offsetX.snapTo(offsetX.value + dragAmount.x)
                            offsetY.snapTo(offsetY.value + dragAmount.y)
                        }
                    }
                )
            }
    ) {
        content(offsetX.value)
    }
}
