# Be-Snap ProGuard / R8 Rules

# Moshi rules
-keepattributes *Annotation*
-keepclassmembers class * {
    @com.squareup.moshi.Json <fields>;
}
-keep @com.squareup.moshi.JsonClass class * { *; }
-keep class *JsonAdapter { *; }
-dontwarn com.squareup.moshi.**

# Retrofit & OkHttp rules
-dontwarn okhttp3.**
-dontwarn okio.**
-dontwarn retrofit2.**
-keepclassmembers,allowobfuscation interface * {
    @retrofit2.http.* <methods>;
}

# Room rules
-keep class * extends androidx.room.RoomDatabase
-dontwarn androidx.room.paging.**
-keep class androidx.room.** { *; }

# Kotlin Coroutines
-keepnames class kotlinx.coroutines.internal.MainDispatcherFactory {}
-keepnames class kotlinx.coroutines.CoroutineExceptionHandler {}
-keepclassmembers class kotlinx.coroutines.** {
    volatile <fields>;
}

# Hilt & Dagger
-keep class * extends dagger.hilt.internal.GeneratedComponentManager { *; }
-dontwarn dagger.hilt.**
-keepclassmembers class * {
    @javax.inject.Inject <init>(...);
    @javax.inject.Inject <fields>;
    @javax.inject.Inject <methods>;
}

# AndroidX Security Crypto
-keepclassmembers class androidx.security.crypto.** { *; }

# Timber
-keep class timber.log.** { *; }

# Preserve Line Numbers for Crash Reporting
-keepattributes SourceFile,LineNumberTable
