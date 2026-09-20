package com.besnap.feature.discover.ui

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.besnap.core.common.BeSnapResult
import com.besnap.feature.discover.data.DiscoverRepository
import com.besnap.feature.discover.model.DiscoverCard
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import javax.inject.Inject

sealed interface DiscoverUiState {
    data object Loading : DiscoverUiState
    data class Success(
        val cards: List<DiscoverCard>,
        val currentIndex: Int = 0,
        val matchEvent: String? = null
    ) : DiscoverUiState
    data class Error(val message: String) : DiscoverUiState
    data object Empty : DiscoverUiState
}

@HiltViewModel
class DiscoverViewModel @Inject constructor(
    private val repository: DiscoverRepository
) : ViewModel() {

    private val _uiState = MutableStateFlow<DiscoverUiState>(DiscoverUiState.Loading)
    val uiState: StateFlow<DiscoverUiState> = _uiState.asStateFlow()

    init {
        refresh()
    }

    fun refresh() {
        _uiState.value = DiscoverUiState.Loading
        viewModelScope.launch {
            when (val result = repository.getFeed()) {
                is BeSnapResult.Success -> {
                    if (result.data.isEmpty()) {
                        _uiState.value = DiscoverUiState.Empty
                    } else {
                        _uiState.value = DiscoverUiState.Success(cards = result.data)
                    }
                }
                is BeSnapResult.Error -> {
                    _uiState.value = DiscoverUiState.Error(result.message)
                }
                is BeSnapResult.Loading -> {
                    // Do nothing here, we already set Loading
                }
            }
        }
    }

    fun onSwipeLeft() {
        val currentCard = getCurrentCard() ?: return
        advanceToNextCard()
        viewModelScope.launch {
            repository.passUser(currentCard.userId)
        }
    }

    fun onSwipeRight() {
        val currentCard = getCurrentCard() ?: return
        advanceToNextCard()
        viewModelScope.launch {
            val result = repository.likeUser(currentCard.userId)
            if (result is BeSnapResult.Success && result.data.matched) {
                _uiState.update { currentState ->
                    if (currentState is DiscoverUiState.Success) {
                        currentState.copy(matchEvent = "You matched with ${currentCard.displayName}!")
                    } else {
                        currentState
                    }
                }
            }
        }
    }

    fun onLikeClicked() {
        onSwipeRight()
    }

    fun onPassClicked() {
        onSwipeLeft()
    }

    fun consumeMatchEvent() {
        _uiState.update { currentState ->
            if (currentState is DiscoverUiState.Success) {
                currentState.copy(matchEvent = null)
            } else {
                currentState
            }
        }
    }

    private fun getCurrentCard(): DiscoverCard? {
        val state = _uiState.value
        return if (state is DiscoverUiState.Success && state.currentIndex < state.cards.size) {
            state.cards[state.currentIndex]
        } else {
            null
        }
    }

    private fun advanceToNextCard() {
        _uiState.update { currentState ->
            if (currentState is DiscoverUiState.Success) {
                if (currentState.currentIndex + 1 >= currentState.cards.size) {
                    DiscoverUiState.Empty
                } else {
                    currentState.copy(currentIndex = currentState.currentIndex + 1)
                }
            } else {
                currentState
            }
        }
    }
}
