package com.besnap.feature.onboarding

import android.content.Context
import androidx.credentials.CredentialManager
import androidx.credentials.GetCredentialRequest
import androidx.credentials.exceptions.GetCredentialException
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.besnap.core.auth.SessionManager
import com.besnap.core.network.BeSnapApi
import com.besnap.core.network.model.GoogleAuthRequest
import com.besnap.feature.onboarding.model.Gender
import com.besnap.feature.onboarding.model.LookingFor
import com.besnap.feature.onboarding.model.OnboardingData
import com.besnap.feature.onboarding.model.OnboardingStep
import com.google.android.libraries.identity.googleid.GetGoogleIdOption
import com.google.android.libraries.identity.googleid.GoogleIdTokenCredential
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import timber.log.Timber
import javax.inject.Inject

import com.besnap.feature.onboarding.data.OnboardingRepository

@HiltViewModel
class OnboardingViewModel @Inject constructor(
    private val api: BeSnapApi,
    private val sessionManager: SessionManager,
    private val onboardingRepository: OnboardingRepository,
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
            if (current.contains(interest)) current.remove(interest) else current.add(interest)
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

    /**
     * Launch the Google Sign-In flow using Credential Manager.
     * The context must be an Activity context (passed from the Composable via LocalContext).
     */
    fun signInWithGoogle(context: Context) {
        viewModelScope.launch {
            _isLoading.value = true
            _error.value = null
            try {
                val credentialManager = CredentialManager.create(context)

                val googleIdOption = GetGoogleIdOption.Builder()
                    .setFilterByAuthorizedAccounts(false)
                    .setServerClientId(com.besnap.feature.onboarding.BuildConfig.GOOGLE_WEB_CLIENT_ID)
                    .setAutoSelectEnabled(false)
                    .build()

                val request = GetCredentialRequest.Builder()
                    .addCredentialOption(googleIdOption)
                    .build()

                val result = credentialManager.getCredential(context = context, request = request)
                val credential = result.credential

                val googleIdTokenCredential = GoogleIdTokenCredential.createFrom(credential.data)
                val idToken = googleIdTokenCredential.idToken

                // Send to Be-Snap backend
                val authResponse = api.googleAuth(GoogleAuthRequest(idToken = idToken))
                sessionManager.setAccessToken(authResponse.accessToken)

                // If returning user with onboarding done, skip to COMPLETE
                if (!authResponse.isNewUser && authResponse.onboardingDone) {
                    _currentStep.value = OnboardingStep.COMPLETE
                } else {
                    nextStep() // go to NAME_DOB
                }
            } catch (e: GetCredentialException) {
                Timber.e(e, "Google Sign-In failed")
                _error.value = "Sign-in failed. Please try again."
            } catch (e: Exception) {
                Timber.e(e, "Authentication failed")
                _error.value = "Authentication failed: ${e.message}"
            } finally {
                _isLoading.value = false
            }
        }
    }

    fun setGender(g: Gender) { _onboardingData.update { it.copy(gender = g) } }

    fun completeOnboarding(latitude: Double, longitude: Double) {
        viewModelScope.launch {
            _isLoading.value = true
            _error.value = null
            try {
                val data = _onboardingData.value
                val request = com.besnap.core.network.model.CompleteOnboardingRequest(
                    displayName = data.displayName,
                    dateOfBirth = data.dob,
                    gender = data.gender?.name ?: "OTHER",
                    lookingFor = data.lookingFor.name,
                    interestIds = data.selectedInterests.toList(), // These are interest IDs
                    minAge = data.minAge,
                    maxAge = data.maxAge,
                    maxDistanceKm = data.maxDistanceKm,
                    genders = data.interestedInGenders.map { it.name },
                    latitude = latitude,
                    longitude = longitude,
                    bio = data.bio,
                )
                val result = onboardingRepository.completeOnboarding(request)
                if (result.isSuccess) {
                    nextStep()
                } else {
                    _error.value = result.exceptionOrNull()?.message ?: "Failed to save profile"
                }
            } catch (e: Exception) {
                _error.value = "Failed to save profile: ${e.message}"
            } finally {
                _isLoading.value = false
            }
        }
    }
}
