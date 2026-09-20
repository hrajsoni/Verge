package com.besnap.feature.onboarding.ui

import androidx.compose.animation.Crossfade
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.hilt.navigation.compose.hiltViewModel
import com.besnap.feature.onboarding.OnboardingViewModel
import com.besnap.feature.onboarding.model.OnboardingStep

@Composable
fun OnboardingScreen(
    onComplete: () -> Unit,
    modifier: Modifier = Modifier,
    viewModel: OnboardingViewModel = hiltViewModel()
) {
    val currentStep by viewModel.currentStep.collectAsState()
    val onboardingData by viewModel.onboardingData.collectAsState()
    val isLoading by viewModel.isLoading.collectAsState()
    val error by viewModel.error.collectAsState()
    val context = LocalContext.current

    LaunchedEffect(currentStep) {
        if (currentStep == OnboardingStep.COMPLETE) {
            onComplete()
        }
    }

    Crossfade(targetState = currentStep, label = "Onboarding Step", modifier = modifier) { step ->
        when (step) {
            OnboardingStep.WELCOME -> WelcomeScreen(
                onGetStarted = viewModel::nextStep
            )
            OnboardingStep.AUTH -> AuthScreen(
                onSignInWithGoogle = { viewModel.signInWithGoogle(context) },
                isLoading = isLoading,
                error = error,
                onBack = viewModel::previousStep,
            )
            OnboardingStep.NAME_DOB -> NameDobScreen(
                displayName = onboardingData.displayName,
                dob = onboardingData.dob,
                onNameChange = viewModel::onDisplayNameChanged,
                onDobChange = viewModel::onDobChanged,
                onNext = viewModel::nextStep,
                onBack = viewModel::previousStep
            )
            OnboardingStep.PHOTO -> PhotoScreen(
                onNext = viewModel::nextStep,
                onSkip = viewModel::nextStep,
                onBack = viewModel::previousStep
            )
            OnboardingStep.INTERESTS -> InterestsScreen(
                selectedInterests = onboardingData.selectedInterests,
                onToggleInterest = viewModel::toggleInterest,
                onNext = viewModel::nextStep,
                onBack = viewModel::previousStep
            )
            OnboardingStep.LOOKING_FOR -> LookingForScreen(
                selectedOption = onboardingData.lookingFor,
                onOptionSelected = viewModel::setLookingFor,
                onNext = viewModel::nextStep,
                onBack = viewModel::previousStep
            )
            OnboardingStep.DISCOVERY_PREFS -> DiscoveryPrefsScreen(
                minAge = onboardingData.minAge,
                maxAge = onboardingData.maxAge,
                maxDistanceKm = onboardingData.maxDistanceKm,
                interestedInGenders = onboardingData.interestedInGenders,
                onPreferencesChanged = viewModel::setPreferences,
                onNext = viewModel::nextStep,
                onBack = viewModel::previousStep
            )
            OnboardingStep.LOCATION -> LocationScreen(
                onAllowLocation = { lat, lon -> viewModel.completeOnboarding(lat, lon) },
                onBack = viewModel::previousStep
            )
            OnboardingStep.COMPLETE -> {
                // Just a blank placeholder, will navigate away via LaunchedEffect
            }
        }
    }
}
