package com.besnap.feature.chat

import androidx.lifecycle.SavedStateHandle
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.besnap.feature.chat.data.ChatRepository
import com.besnap.feature.chat.model.ChatMessage
import com.besnap.feature.chat.model.ChatMessageType
import com.besnap.feature.chat.model.SnapViewState
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import timber.log.Timber
import java.time.LocalDateTime
import javax.inject.Inject

data class ChatUiState(
    val conversationId: String = "",
    val messages: List<ChatMessage> = emptyList(),
    val inputText: String = "",
    val isTyping: Boolean = false,
    val isOtherTyping: Boolean = false,
    val isLoading: Boolean = false
)

@HiltViewModel
class ChatViewModel @Inject constructor(
    private val repository: ChatRepository,
    savedStateHandle: SavedStateHandle
) : ViewModel() {

    private val conversationId: String = savedStateHandle.get<String>("conversationId") ?: ""

    private val _uiState = MutableStateFlow(ChatUiState(conversationId = conversationId))
    val uiState: StateFlow<ChatUiState> = _uiState.asStateFlow()

    init {
        loadMessages()
    }

    fun loadMessages() {
        if (conversationId.isBlank()) return
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true) }
            repository.getMessages(conversationId).onSuccess { dtoMessages ->
                val messages = dtoMessages.map { dto ->
                    ChatMessage(
                        id = dto.id,
                        conversationId = conversationId,
                        senderId = dto.senderId,
                        isMine = dto.senderId == "me", // Placeholder for actual ID check
                        type = if (dto.isSnap) ChatMessageType.SNAP else if (dto.mediaId != null) ChatMessageType.PHOTO else ChatMessageType.TEXT,
                        text = dto.text,
                        mediaUrl = dto.mediaId,
                        timestamp = LocalDateTime.now(), // Placeholder for parsing dto.sentAt
                        snapViewState = dto.snapViewState?.let { state ->
                            runCatching { SnapViewState.valueOf(state) }.getOrNull()
                        } ?: SnapViewState.UNOPENED
                    )
                }
                _uiState.update { it.copy(isLoading = false, messages = messages) }
            }.onFailure {
                Timber.e(it, "Failed to load messages")
                _uiState.update { it.copy(isLoading = false) }
            }
        }
    }

    fun onTextChanged(text: String) {
        _uiState.update { it.copy(inputText = text, isTyping = text.isNotEmpty()) }
    }

    fun sendMessage() {
        val text = _uiState.value.inputText
        if (text.isBlank()) return
        
        _uiState.update { it.copy(inputText = "", isTyping = false) }
        viewModelScope.launch {
            repository.sendMessage(conversationId, text).onSuccess { dto ->
                loadMessages() // Refresh messages
            }.onFailure {
                Timber.e(it, "Failed to send message")
            }
        }
    }

    fun sendSnap() {
    }
}
