package com.besnap.feature.chat.data

import com.besnap.core.network.BeSnapApi
import com.besnap.core.network.model.ConversationDto
import com.besnap.core.network.model.MessageDto
import com.besnap.core.network.model.SendMessageRequest
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class ChatRepository @Inject constructor(
    private val api: BeSnapApi,
) {
    suspend fun getConversations(): Result<List<ConversationDto>> = runCatching {
        api.getConversations()
    }

    suspend fun getMessages(conversationId: String): Result<List<MessageDto>> = runCatching {
        api.getMessages(conversationId)
    }

    suspend fun sendMessage(conversationId: String, text: String): Result<MessageDto> = runCatching {
        api.sendMessage(conversationId, SendMessageRequest(text = text))
    }
}
