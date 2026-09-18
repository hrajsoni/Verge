package com.besnap.app.navigation

import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Chat
import androidx.compose.material.icons.filled.Favorite
import androidx.compose.material.icons.filled.LocalFireDepartment
import androidx.compose.material.icons.filled.Person
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

object BeSnapRoutes {
    const val DISCOVER = "discover"
    const val MATCHES = "matches"
    const val CHATS = "chats"
    const val PROFILE = "profile"
}

data class TopLevelRoute(
    val name: String,
    val route: String,
    val icon: ImageVector,
)

val topLevelRoutes = listOf(
    TopLevelRoute("Discover", BeSnapRoutes.DISCOVER, Icons.Default.LocalFireDepartment),
    TopLevelRoute("Matches", BeSnapRoutes.MATCHES, Icons.Default.Favorite),
    TopLevelRoute("Chats", BeSnapRoutes.CHATS, Icons.Default.Chat),
    TopLevelRoute("Profile", BeSnapRoutes.PROFILE, Icons.Default.Person),
)

@Composable
fun BeSnapApp() {
    BeSnapTheme {
        val navController = rememberNavController()
        Scaffold(
            modifier = Modifier.fillMaxSize(),
            bottomBar = {
                val navBackStackEntry by navController.currentBackStackEntryAsState()
                val currentRoute = navBackStackEntry?.destination?.route
                NavigationBar {
                    topLevelRoutes.forEach { topLevelRoute ->
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
                    }
                }
            }
        ) { innerPadding ->
            NavHost(
                navController = navController,
                startDestination = BeSnapRoutes.DISCOVER,
                modifier = Modifier.padding(innerPadding)
            ) {
                composable(BeSnapRoutes.DISCOVER) {
                    PlaceholderScreen("\uD83D\uDD25 Discover")
                }
                composable(BeSnapRoutes.MATCHES) {
                    PlaceholderScreen("\uD83D\uDC9C Matches")
                }
                composable(BeSnapRoutes.CHATS) {
                    PlaceholderScreen("\uD83D\uDCAC Chats")
                }
                composable(BeSnapRoutes.PROFILE) {
                    PlaceholderScreen("\uD83D\uDC64 Profile")
                }
            }
        }
    }
}
