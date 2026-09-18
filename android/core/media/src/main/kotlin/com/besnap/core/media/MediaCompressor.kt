package com.besnap.core.media

import android.content.Context
import android.net.Uri
import timber.log.Timber
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class MediaCompressor @Inject constructor() {

    suspend fun compressImage(context: Context, uri: Uri, maxWidth: Int = 1080): Uri {
        Timber.d("Compressing image: $uri")
        // TODO: Implement image compression
        return uri
    }

    suspend fun compressVideo(context: Context, uri: Uri): Uri {
        Timber.d("Compressing video: $uri")
        // TODO: Implement video compression
        return uri
    }
}
