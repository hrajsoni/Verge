package com.besnap.feature.discover.ui

import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.tween
import androidx.compose.foundation.gestures.detectDragGestures
import androidx.compose.foundation.layout.Box
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.unit.dp
import kotlinx.coroutines.launch
import kotlin.math.abs

@Composable
fun SwipeableCard(
    onSwipedLeft: () -> Unit,
    onSwipedRight: () -> Unit,
    modifier: Modifier = Modifier,
    content: @Composable () -> Unit,
) {
    val density = LocalDensity.current
    val screenWidthPx = with(density) { LocalConfiguration.current.screenWidthDp.dp.toPx() }
    val swipeThreshold = screenWidthPx * 0.3f

    val offsetX = remember { Animatable(0f) }
    val offsetY = remember { Animatable(0f) }
    val coroutineScope = rememberCoroutineScope()

    Box(
        modifier = modifier
            .graphicsLayer {
                // Reading Animatable.value inside graphicsLayer lambda runs in the
                // drawing phase — no recomposition triggered on every frame.
                translationX = offsetX.value
                translationY = offsetY.value
                val progress = (offsetX.value / screenWidthPx).coerceIn(-1f, 1f)
                rotationZ = progress * 15f
            }
            .pointerInput(Unit) {
                detectDragGestures(
                    onDragEnd = {
                        coroutineScope.launch {
                            val targetX = offsetX.value
                            if (abs(targetX) > swipeThreshold) {
                                val finalX = if (targetX > 0) screenWidthPx * 1.5f else -screenWidthPx * 1.5f
                                offsetX.animateTo(finalX, tween(300))
                                if (targetX > 0) onSwipedRight() else onSwipedLeft()
                            } else {
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
                    },
                )
            },
    ) {
        content()
    }
}
