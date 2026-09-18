package com.besnap.feature.matches.navigation

import androidx.navigation.NavController
import androidx.navigation.NavGraphBuilder
import androidx.navigation.NavOptions
import androidx.navigation.compose.composable
import com.besnap.feature.matches.ui.MatchesRoute

const val MATCHES_ROUTE = "matches_route"

fun NavController.navigateToMatches(navOptions: NavOptions? = null) {
    this.navigate(MATCHES_ROUTE, navOptions)
}

fun NavGraphBuilder.matchesScreen(
    onNavigateToChat: (String) -> Unit
) {
    composable(route = MATCHES_ROUTE) {
        MatchesRoute(
            onNavigateToChat = onNavigateToChat
        )
    }
}
