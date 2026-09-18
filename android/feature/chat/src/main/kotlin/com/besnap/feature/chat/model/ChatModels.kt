package com.besnap.feature.chat.model

import java.time.LocalDateTime

enum class ChatMessageType {
    TEXT, PHOTO, VIDEO, VOICE, SNAP
}

enum class SnapViewState {
    UNOPENED, OPENED, EXPIRED
}

data class ChatMessage(
    val id: String,
    val conversationId: String,
    val senderId: String,
    val isMine: Boolean,
    val type: ChatMessageType,
    val text: String?,
    val mediaUrl: String?,
    val timestamp: LocalDateTime,
    val snapViewState: SnapViewState? = null
)
