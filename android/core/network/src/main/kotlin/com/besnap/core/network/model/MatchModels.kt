package com.besnap.core.network.model

import com.squareup.moshi.JsonClass

@JsonClass(generateAdapter = true)
data class MatchDto(
    val id: String,
    val userId: String,
    val displayName: String,
    val avatarUrl: String?,
    val matchedAt: String,
    val conversationId: String?,
)

@JsonClass(generateAdapter = true)
data class ConversationDto(
    val id: String,
    val otherUser: OtherUserDto,
    val lastMessage: LastMessageDto?,
    val unreadCount: Int = 0,
    val updatedAt: String,
)

@JsonClass(generateAdapter = true)
data class OtherUserDto(
    val id: String,
    val displayName: String,
    val avatarUrl: String?,
)

@JsonClass(generateAdapter = true)
data class LastMessageDto(
    val id: String,
    val text: String?,
    val isSnap: Boolean = false,
    val sentAt: String,
)

@JsonClass(generateAdapter = true)
data class MessageDto(
    val id: String,
    val senderId: String,
    val text: String?,
    val mediaId: String?,
    val isSnap: Boolean = false,
    val snapViewState: String?,
    val sentAt: String,
)

@JsonClass(generateAdapter = true)
data class SendMessageRequest(
    val text: String? = null,
    val mediaId: String? = null,
    val snapViewDuration: Int? = null,
    val snapMaxViews: Int? = null,
)
