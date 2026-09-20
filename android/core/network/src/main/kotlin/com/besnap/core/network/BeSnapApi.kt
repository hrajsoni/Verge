package com.besnap.core.network

import com.besnap.core.network.model.AuthResponse
import com.besnap.core.network.model.InterestDto
import com.besnap.core.network.model.GoogleAuthRequest
import com.besnap.core.network.model.UserResponse
import retrofit2.http.Body
import retrofit2.http.GET
import retrofit2.http.POST

interface BeSnapApi {

    @POST("auth/google")
    suspend fun googleAuth(@Body request: GoogleAuthRequest): AuthResponse

    @GET("users/me")
    suspend fun getMe(): UserResponse

    @GET("interests")
    suspend fun getInterests(): List<InterestDto>

    @GET("discover/feed")
    suspend fun getFeed(): List<com.besnap.core.network.model.DiscoverFeedItemDto>

    @POST("discover/like/{userId}")
    suspend fun likeUser(@retrofit2.http.Path("userId") userId: String): com.besnap.core.network.model.SwipeResponseDto

    @POST("discover/pass/{userId}")
    suspend fun passUser(@retrofit2.http.Path("userId") userId: String)

    // Matches
    @GET("matching/matches")
    suspend fun getMatches(): List<com.besnap.core.network.model.MatchDto>

    // Chat
    @GET("chat/conversations")
    suspend fun getConversations(): List<com.besnap.core.network.model.ConversationDto>

    @GET("chat/conversations/{conversationId}/messages")
    suspend fun getMessages(
        @retrofit2.http.Path("conversationId") conversationId: String,
        @retrofit2.http.Query("limit") limit: Int = 50,
    ): List<com.besnap.core.network.model.MessageDto>

    @POST("chat/conversations/{conversationId}/messages")
    suspend fun sendMessage(
        @retrofit2.http.Path("conversationId") conversationId: String,
        @Body request: com.besnap.core.network.model.SendMessageRequest,
    ): com.besnap.core.network.model.MessageDto

    @POST("users/me/onboarding")
    suspend fun completeOnboarding(@Body request: com.besnap.core.network.model.CompleteOnboardingRequest): com.besnap.core.network.model.OnboardingResponse
}
