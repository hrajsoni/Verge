package com.besnap.core.permissions

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.content.ContextCompat

object PermissionManager {

    fun hasPermission(context: Context, permission: String): Boolean {
        return ContextCompat.checkSelfPermission(context, permission) ==
            PackageManager.PERMISSION_GRANTED
    }

    fun hasCameraPermission(context: Context) =
        hasPermission(context, Manifest.permission.CAMERA)

    fun hasAudioPermission(context: Context) =
        hasPermission(context, Manifest.permission.RECORD_AUDIO)

    fun hasLocationPermission(context: Context) =
        hasPermission(context, Manifest.permission.ACCESS_FINE_LOCATION)

    fun hasNotificationPermission(context: Context): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            hasPermission(context, Manifest.permission.POST_NOTIFICATIONS)
        } else {
            true
        }
    }
}
