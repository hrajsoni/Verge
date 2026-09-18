package com.besnap.feature.onboarding

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.besnap.core.auth.SessionManager
import com.besnap.core.network.BeSnapApi
import com.besnap.core.network.model.LoginRequest
import com.besnap.core.network.model.RegisterRequest
import com.besnap.feature.onboarding.model.Gender
import com.besnap.feature.onboarding.model.LookingFor
import com.besnap.feature.onboarding.model.OnboardingData
import com.besnap.feature.onboarding.model.OnboardingStep
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import timber.log.Timber
import javax.inject.Inject

@HiltViewModel
class OnboardingViewModel @Inject constructor(
    private val api: BeSnapApi,
    private val sessionManager: SessionManager
) : ViewModel() {

    private val _currentStep = MutableStateFlow(OnboardingStep.WELCOME)
    val currentStep: StateFlow<OnboardingStep> = _currentStep.asStateFlow()

    private val _onboardingData = MutableStateFlow(OnboardingData())
    val onboardingData: StateFlow<OnboardingData> = _onboardingData.asStateFlow()

    private val _isLoading = MutableStateFlow(false)
    val isLoading: StateFlow<Boolean> = _isLoading.asStateFlow()

    private val _error = MutableStateFlow<String?>(null)
    val error: StateFlow<String?> = _error.asStateFlow()

    fun nextStep() {
        val next = when (_currentStep.value) {
            OnboardingStep.WELCOME -> OnboardingStep.AUTH
            OnboardingStep.AUTH -> OnboardingStep.NAME_DOB
            OnboardingStep.NAME_DOB -> OnboardingStep.PHOTO
            OnboardingStep.PHOTO -> OnboardingStep.INTERESTS
            OnboardingStep.INTERESTS -> OnboardingStep.LOOKING_FOR
            OnboardingStep.LOOKING_FOR -> OnboardingStep.DISCOVERY_PREFS
            OnboardingStep.DISCOVERY_PREFS -> OnboardingStep.LOCATION
            OnboardingStep.LOCATION -> OnboardingStep.COMPLETE
            OnboardingStep.COMPLETE -> OnboardingStep.COMPLETE
        }
        _currentStep.value = next
    }

    fun previousStep() {
        val prev = when (_currentStep.value) {
            OnboardingStep.WELCOME -> OnboardingStep.WELCOME
            OnboardingStep.AUTH -> OnboardingStep.WELCOME
            OnboardingStep.NAME_DOB -> OnboardingStep.AUTH
            OnboardingStep.PHOTO -> OnboardingStep.NAME_DOB
            OnboardingStep.INTERESTS -> OnboardingStep.PHOTO
            OnboardingStep.LOOKING_FOR -> OnboardingStep.INTERESTS
            OnboardingStep.DISCOVERY_PREFS -> OnboardingStep.LOOKING_FOR
            OnboardingStep.LOCATION -> OnboardingStep.DISCOVERY_PREFS
            OnboardingStep.COMPLETE -> OnboardingStep.LOCATION
        }
        _currentStep.value = prev
    }

    fun onDisplayNameChanged(name: String) {
        _onboardingData.update { it.copy(displayName = name) }
    }

    fun onDobChanged(dob: String) {
        _onboardingData.update { it.copy(dob = dob) }
    }

    fun toggleInterest(interest: String) {
        _onboardingData.update {
            val current = it.selectedInterests.toMutableSet()
            if (current.contains(interest)) {
                current.remove(interest)
            } else {
                current.add(interest)
            }
            it.copy(selectedInterests = current)
        }
    }

    fun setLookingFor(lookingFor: LookingFor) {
        _onboardingData.update { it.copy(lookingFor = lookingFor) }
    }

    fun setPreferences(minAge: Int, maxAge: Int, distance: Int, genders: Set<Gender>) {
        _onboardingData.update { 
            it.copy(minAge = minAge, maxAge = maxAge, maxDistanceKm = distance, interestedInGenders = genders)
        }
    }

    fun clearError() {
        _error.value = null
    }

    fun register(email: String, pass: String) {
        viewModelScope.launch {
            _isLoading.value = true
            _error.value = null
            try {
                val data = _onboardingData.value
                val res = api.register(
                    RegisterRequest(
                        email = email,
                        password = pass,
                        displayName = data.displayName.ifEmpty { "User" },
                        dateOfBirth = data.dob.ifEmpty { "2000-01-01" }
                    )
                )
                sessionManager.setAccessToken(res.accessToken)
                nextStep()
            } catch (e: Exception) {
                Timber.e(e, "Registration failed")
                _error.value = "Registration failed: ${e.message}"
            } finally {
                _isLoading.value = false
            }
        }
    }

    fun login(email: String, pass: String) {
        viewModelScope.launch {
            _isLoading.value = true
            _error.value = null
            try {
                val res = api.login(LoginRequest(email, pass))
                sessionManager.setAccessToken(res.accessToken)
                nextStep()
            } catch (e: Exception) {
                Timber.e(e, "Login failed")
                _error.value = "Login failed: \${e.message}"
            } finally {
                _isLoading.value = false
            }
        }
    }

    fun completeOnboarding() {
        // Assume API call to save profile details happens here
        nextStep() // complete
    }
}
