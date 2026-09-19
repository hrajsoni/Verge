package com.besnap.app.navigation

import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.Chat
import androidx.compose.material.icons.filled.Favorite
import androidx.compose.material.icons.filled.LocalFireDepartment
import androidx.compose.material.icons.filled.Person
import androidx.compose.material.icons.filled.PhotoCamera
import androidx.compose.material3.Icon
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.navigation.NavGraph.Companion.findStartDestination
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController
import com.besnap.core.design.theme.BeSnapTheme
import com.besnap.feature.camera.navigation.CAMERA_ROUTE
import com.besnap.feature.camera.navigation.cameraScreen
import com.besnap.feature.camera.navigation.navigateToCamera
import com.besnap.feature.chat.navigation.CHAT_ROUTE_PREFIX
import com.besnap.feature.chat.navigation.chatScreen
import com.besnap.feature.chat.navigation.navigateToChat
import com.besnap.feature.discover.navigation.DISCOVER_ROUTE
import com.besnap.feature.discover.navigation.discoverScreen
import com.besnap.feature.discover.navigation.navigateToDiscover
import com.besnap.feature.matches.navigation.MATCHES_ROUTE
import com.besnap.feature.matches.navigation.matchesScreen
import com.besnap.feature.matches.navigation.navigateToMatches
import com.besnap.feature.onboarding.onboardingGraph
import com.besnap.feature.onboarding.onboardingRoute

object BeSnapRoutes {
    const val PROFILE = "profile_route"
}

data class TopLevelRoute(
    val name: String,
    val route: String,
    val icon: ImageVector,
)

val topLevelRoutes = listOf(
    TopLevelRoute("Discover", DISCOVER_ROUTE, Icons.Default.LocalFireDepartment),
    TopLevelRoute("Camera", CAMERA_ROUTE, Icons.Default.PhotoCamera),
    TopLevelRoute("Matches", MATCHES_ROUTE, Icons.Default.Favorite),
    TopLevelRoute("Profile", BeSnapRoutes.PROFILE, Icons.Default.Person),
)

@Composable
fun BeSnapApp(isLoggedIn: Boolean = false) {
    BeSnapTheme {
        val navController = rememberNavController()
        val navBackStackEntry by navController.currentBackStackEntryAsState()
        val currentRoute = navBackStackEntry?.destination?.route

        val showBottomBar = currentRoute in listOf(
            DISCOVER_ROUTE,
            MATCHES_ROUTE,
            BeSnapRoutes.PROFILE,
        )

        Scaffold(
            modifier = Modifier.fillMaxSize(),
            bottomBar = {
                if (showBottomBar) {
                    NavigationBar {
                        topLevelRoutes.forEach { topLevelRoute ->
                            if (topLevelRoute.route != CAMERA_ROUTE) {
                                NavigationBarItem(
                                    icon = { Icon(topLevelRoute.icon, contentDescription = topLevelRoute.name) },
                                    label = { Text(topLevelRoute.name) },
                                    selected = currentRoute == topLevelRoute.route,
                                    onClick = {
                                        navController.navigate(topLevelRoute.route) {
                                            popUpTo(navController.graph.findStartDestination().id) {
                                                saveState = true
                                            }
                                            launchSingleTop = true
                                            restoreState = true
                                        }
                                    }
                                )
                            } else {
                                NavigationBarItem(
                                    icon = { Icon(topLevelRoute.icon, contentDescription = topLevelRoute.name) },
                                    label = { Text(topLevelRoute.name) },
                                    selected = false,
                                    onClick = { navController.navigateToCamera() }
                                )
                            }
                        }
                    }
                }
            }
        ) { innerPadding ->
            NavHost(
                navController = navController,
                startDestination = if (isLoggedIn) DISCOVER_ROUTE else onboardingRoute,
                modifier = Modifier.padding(innerPadding)
            ) {
                discoverScreen()
                
                matchesScreen(
                    onNavigateToChat = { conversationId ->
                        navController.navigateToChat(conversationId)
                    }
                )

                chatScreen(
                    onBackClick = { navController.popBackStack() }
                )

                cameraScreen(
                    onCloseClick = { navController.popBackStack() },
                    onGalleryClick = { /* open gallery */ }
                )

                onboardingGraph(
                    onOnboardingComplete = {
                        navController.navigate(DISCOVER_ROUTE) {
                            popUpTo(onboardingRoute) { inclusive = true }
                        }
                    }
                )

                composable(BeSnapRoutes.PROFILE) {
                    PlaceholderScreen("👤 Profile")
                }
            }
        }
    }
}
