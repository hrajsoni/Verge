package com.besnap.core.network

import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.components.SingletonComponent
import retrofit2.Retrofit
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
object ApiModule {

    @Provides
    @Singleton
    fun provideBeSnapApi(retrofit: Retrofit): BeSnapApi {
        return retrofit.create(BeSnapApi::class.java)
    }
}
