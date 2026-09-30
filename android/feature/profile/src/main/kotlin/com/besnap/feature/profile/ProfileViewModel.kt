package com.besnap.feature.profile

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.besnap.core.network.model.ProfileResponse
import com.besnap.core.network.model.UpdateProfileRequest
import com.besnap.feature.profile.data.ProfileRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

sealed interface ProfileUiState {
    object Loading : ProfileUiState
    data class Success(val profile: ProfileResponse, val isEditing: Boolean = false) : ProfileUiState
    data class Error(val message: String) : ProfileUiState
}

@HiltViewModel
class ProfileViewModel @Inject constructor(
    private val repository: ProfileRepository,
) : ViewModel() {

    private val _uiState = MutableStateFlow<ProfileUiState>(ProfileUiState.Loading)
    val uiState: StateFlow<ProfileUiState> = _uiState.asStateFlow()

    // Edit fields
    val editDisplayName = MutableStateFlow("")
    val editBio = MutableStateFlow("")

    init { loadProfile() }

    fun loadProfile() {
        viewModelScope.launch {
            _uiState.value = ProfileUiState.Loading
            repository.getMyProfile()
                .onSuccess { profile ->
                    editDisplayName.value = profile.displayName
                    editBio.value = profile.bio ?: ""
                    _uiState.value = ProfileUiState.Success(profile)
                }
                .onFailure {
                    _uiState.value = ProfileUiState.Error(it.message ?: "Failed to load profile")
                }
        }
    }

    fun startEditing() {
        val current = _uiState.value as? ProfileUiState.Success ?: return
        _uiState.value = current.copy(isEditing = true)
    }

    fun cancelEditing() {
        val current = _uiState.value as? ProfileUiState.Success ?: return
        editDisplayName.value = current.profile.displayName
        editBio.value = current.profile.bio ?: ""
        _uiState.value = current.copy(isEditing = false)
    }

    fun saveProfile() {
        val current = _uiState.value as? ProfileUiState.Success ?: return
        viewModelScope.launch {
            repository.updateProfile(
                UpdateProfileRequest(
                    displayName = editDisplayName.value.takeIf { it.isNotBlank() },
                    bio = editBio.value.takeIf { it.isNotBlank() },
                    gender = null,
                )
            ).onSuccess { updated ->
                _uiState.value = ProfileUiState.Success(updated, isEditing = false)
            }.onFailure {
                // Keep editing state, show error later
            }
        }
    }
}
