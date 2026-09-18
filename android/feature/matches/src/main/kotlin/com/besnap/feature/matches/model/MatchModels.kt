package com.besnap.feature.matches.model

import java.time.LocalDateTime

data class MatchItem(
    val matchId: String,
    val userId: String,
    val displayName: String,
    val photoUrl: String?,
    val matchedAt: LocalDateTime,
    val conversationId: String?,
    val lastMessage: String?,
    val unreadCount: Int
)
