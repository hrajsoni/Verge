package com.besnap.core.network

import com.besnap.core.network.model.AuthResponse
import com.besnap.core.network.model.InterestDto
import com.besnap.core.network.model.LoginRequest
import com.besnap.core.network.model.RegisterRequest
import com.besnap.core.network.model.UserResponse
import retrofit2.http.Body
import retrofit2.http.GET
import retrofit2.http.POST

interface BeSnapApi {

    @POST("auth/register")
    suspend fun register(@Body request: RegisterRequest): AuthResponse

    @POST("auth/login")
    suspend fun login(@Body request: LoginRequest): AuthResponse

    @GET("users/me")
    suspend fun getMe(): UserResponse

    @GET("interests")
    suspend fun getInterests(): List<InterestDto>
}
