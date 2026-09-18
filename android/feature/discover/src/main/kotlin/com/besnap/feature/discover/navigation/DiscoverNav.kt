package com.besnap.feature.discover.navigation

import androidx.navigation.NavController
import androidx.navigation.NavGraphBuilder
import androidx.navigation.NavOptions
import androidx.navigation.compose.composable
import com.besnap.feature.discover.ui.DiscoverRoute

const val DISCOVER_ROUTE = "discover_route"

fun NavController.navigateToDiscover(navOptions: NavOptions? = null) {
    this.navigate(DISCOVER_ROUTE, navOptions)
}

fun NavGraphBuilder.discoverScreen() {
    composable(route = DISCOVER_ROUTE) {
        DiscoverRoute()
    }
}
