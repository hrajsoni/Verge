package com.besnap.feature.camera.navigation

import androidx.navigation.NavController
import androidx.navigation.NavGraphBuilder
import androidx.navigation.compose.composable
import com.besnap.feature.camera.ui.CameraScreen

const val CAMERA_ROUTE = "camera_route"

fun NavController.navigateToCamera() {
    navigate(CAMERA_ROUTE)
}

fun NavGraphBuilder.cameraScreen(
    onCloseClick: () -> Unit,
    onGalleryClick: () -> Unit
) {
    composable(route = CAMERA_ROUTE) {
        CameraScreen(
            onCloseClick = onCloseClick,
            onGalleryClick = onGalleryClick
        )
    }
}
