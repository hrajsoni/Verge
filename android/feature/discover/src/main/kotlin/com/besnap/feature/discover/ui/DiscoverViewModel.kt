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

data class DiscoverUiState(
    val cards: List<DiscoverCard> = emptyList(),
    val currentIndex: Int = 0,
    val isLoading: Boolean = true,
    val error: String? = null,
    val matchEvent: String? = null
)

@HiltViewModel
class DiscoverViewModel @Inject constructor(
    private val repository: DiscoverRepository
) : ViewModel() {

    private val _uiState = MutableStateFlow(DiscoverUiState())
    val uiState: StateFlow<DiscoverUiState> = _uiState.asStateFlow()

    init {
        refresh()
    }

    fun refresh() {
        _uiState.update { it.copy(isLoading = true, error = null, currentIndex = 0) }
        viewModelScope.launch {
            when (val result = repository.getFeed()) {
                is BeSnapResult.Success -> {
                    _uiState.update { it.copy(cards = result.data, isLoading = false) }
                }
                is BeSnapResult.Error -> {
                    _uiState.update { it.copy(error = result.message, isLoading = false) }
                }
                is BeSnapResult.Loading -> {
                    // Do nothing here, we already set isLoading = true
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
                _uiState.update { it.copy(matchEvent = "You matched with ${currentCard.displayName}!") }
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
        _uiState.update { it.copy(matchEvent = null) }
    }

    private fun getCurrentCard(): DiscoverCard? {
        val state = _uiState.value
        return if (state.currentIndex < state.cards.size) {
            state.cards[state.currentIndex]
        } else {
            null
        }
    }

    private fun advanceToNextCard() {
        _uiState.update { it.copy(currentIndex = it.currentIndex + 1) }
    }
}
