package com.besnap.feature.matches

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.besnap.core.network.model.MatchDto
import com.besnap.feature.matches.data.MatchesRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import timber.log.Timber
import javax.inject.Inject

sealed interface MatchesUiState {
    data object Loading : MatchesUiState
    data class Success(val matches: List<MatchDto>) : MatchesUiState
    data class Error(val message: String) : MatchesUiState
    data object Empty : MatchesUiState
}

@HiltViewModel
class MatchesViewModel @Inject constructor(
    private val repository: MatchesRepository,
) : ViewModel() {

    private val _uiState = MutableStateFlow<MatchesUiState>(MatchesUiState.Loading)
    val uiState: StateFlow<MatchesUiState> = _uiState.asStateFlow()

    init {
        loadMatches()
    }

    fun loadMatches() {
        viewModelScope.launch {
            _uiState.value = MatchesUiState.Loading
            val result = repository.getMatches()
            _uiState.value = result.fold(
                onSuccess = { matches ->
                    if (matches.isEmpty()) MatchesUiState.Empty
                    else MatchesUiState.Success(matches)
                },
                onFailure = { e ->
                    Timber.e(e, "Failed to load matches")
                    MatchesUiState.Error(e.message ?: "Failed to load matches")
                },
            )
        }
    }
}
