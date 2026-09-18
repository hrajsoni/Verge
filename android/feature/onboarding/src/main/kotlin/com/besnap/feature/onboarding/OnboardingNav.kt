package com.besnap.feature.onboarding

import androidx.navigation.NavGraphBuilder
import androidx.navigation.compose.composable
import com.besnap.feature.onboarding.ui.OnboardingScreen

const val onboardingRoute = "onboarding_route"

fun NavGraphBuilder.onboardingGraph(
    onOnboardingComplete: () -> Unit
) {
    composable(route = onboardingRoute) {
        OnboardingScreen(
            onComplete = onOnboardingComplete
        )
    }
}
