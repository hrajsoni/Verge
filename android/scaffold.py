import os

workspace = "e:/be-snap/android"

files = {
    "app/build.gradle.kts": """plugins {
    alias(libs.plugins.android.application)
    alias(libs.plugins.kotlin.android)
    alias(libs.plugins.kotlin.compose)
    alias(libs.plugins.hilt)
    alias(libs.plugins.ksp)
}

android {
    namespace = "com.besnap.app"
    compileSdk = 35

    defaultConfig {
        applicationId = "com.besnap.app"
        minSdk = 26
        targetSdk = 35
        versionCode = 1
        versionName = "0.1.0"
    }

    buildTypes {
        release {
            isMinifyEnabled = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }
}

dependencies {
    implementation(project(":core:common"))
    implementation(project(":core:network"))
    implementation(project(":core:database"))
    implementation(project(":core:auth"))
    implementation(project(":core:design"))
    implementation(project(":core:media"))
    implementation(project(":core:permissions"))

    implementation(project(":feature:onboarding"))
    implementation(project(":feature:discover"))
    implementation(project(":feature:matches"))
    implementation(project(":feature:chat"))
    implementation(project(":feature:camera"))
    implementation(project(":feature:calls"))
    implementation(project(":feature:profile"))
    implementation(project(":feature:notifications"))
    implementation(project(":feature:safety"))

    implementation(libs.androidx.core.ktx)
    implementation(libs.androidx.lifecycle.runtime)
    implementation(libs.androidx.activity.compose)
    implementation(platform(libs.androidx.compose.bom))
    implementation(libs.androidx.compose.ui)
    implementation(libs.androidx.compose.material3)
    implementation(libs.androidx.navigation.compose)
    implementation(libs.androidx.hilt.navigation.compose)
    implementation(libs.hilt.android)
    ksp(libs.hilt.compiler)
    implementation(libs.timber)
}""",
    "app/proguard-rules.pro": """# Be-Snap ProGuard rules
""",
    "app/src/main/AndroidManifest.xml": """<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android">

    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
    <uses-permission android:name="android.permission.CAMERA" />
    <uses-permission android:name="android.permission.RECORD_AUDIO" />
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />

    <application
        android:name=".BeSnapApplication"
        android:allowBackup="false"
        android:icon="@android:drawable/sym_def_app_icon"
        android:label="Be-Snap"
        android:roundIcon="@android:drawable/sym_def_app_icon"
        android:supportsRtl="true"
        android:theme="@style/Theme.BeSnap">

        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:theme="@style/Theme.BeSnap">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>
    </application>
</manifest>""",
    "app/src/main/res/values/strings.xml": """<resources>
    <string name="app_name">Be-Snap</string>
</resources>""",
    "app/src/main/res/values/themes.xml": """<?xml version="1.0" encoding="utf-8"?>
<resources>
    <style name="Theme.BeSnap" parent="android:Theme.Material.NoActionBar" />
</resources>""",
    "app/src/main/kotlin/com/besnap/app/BeSnapApplication.kt": """package com.besnap.app

import android.app.Application
import dagger.hilt.android.HiltAndroidApp
import timber.log.Timber

@HiltAndroidApp
class BeSnapApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        if (BuildConfig.DEBUG) {
            Timber.plant(Timber.DebugTree())
        }
    }
}""",
    "app/src/main/kotlin/com/besnap/app/MainActivity.kt": """package com.besnap.app

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import com.besnap.app.navigation.BeSnapApp
import dagger.hilt.android.AndroidEntryPoint

@AndroidEntryPoint
class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent {
            BeSnapApp()
        }
    }
}""",
    "app/src/main/kotlin/com/besnap/app/navigation/BeSnapApp.kt": """package com.besnap.app.navigation

import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Chat
import androidx.compose.material.icons.filled.Favorite
import androidx.compose.material.icons.filled.LocalFireDepartment
import androidx.compose.material.icons.filled.Person
import androidx.compose.material3.Icon
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.navigation.NavGraph.Companion.findStartDestination
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController
import com.besnap.core.design.theme.BeSnapTheme

object BeSnapRoutes {
    const val DISCOVER = "discover"
    const val MATCHES = "matches"
    const val CHATS = "chats"
    const val PROFILE = "profile"
}

data class TopLevelRoute(
    val name: String,
    val route: String,
    val icon: ImageVector,
)

val topLevelRoutes = listOf(
    TopLevelRoute("Discover", BeSnapRoutes.DISCOVER, Icons.Default.LocalFireDepartment),
    TopLevelRoute("Matches", BeSnapRoutes.MATCHES, Icons.Default.Favorite),
    TopLevelRoute("Chats", BeSnapRoutes.CHATS, Icons.Default.Chat),
    TopLevelRoute("Profile", BeSnapRoutes.PROFILE, Icons.Default.Person),
)

@Composable
fun BeSnapApp() {
    BeSnapTheme {
        val navController = rememberNavController()
        Scaffold(
            modifier = Modifier.fillMaxSize(),
            bottomBar = {
                val navBackStackEntry by navController.currentBackStackEntryAsState()
                val currentRoute = navBackStackEntry?.destination?.route
                NavigationBar {
                    topLevelRoutes.forEach { topLevelRoute ->
                        NavigationBarItem(
                            icon = { Icon(topLevelRoute.icon, contentDescription = topLevelRoute.name) },
                            label = { Text(topLevelRoute.name) },
                            selected = currentRoute == topLevelRoute.route,
                            onClick = {
                                navController.navigate(topLevelRoute.route) {
                                    popUpTo(navController.graph.findStartDestination().id) {
                                        saveState = true
                                    }
                                    launchSingleTop = true
                                    restoreState = true
                                }
                            }
                        )
                    }
                }
            }
        ) { innerPadding ->
            NavHost(
                navController = navController,
                startDestination = BeSnapRoutes.DISCOVER,
                modifier = Modifier.padding(innerPadding)
            ) {
                composable(BeSnapRoutes.DISCOVER) {
                    PlaceholderScreen("\uD83D\uDD25 Discover")
                }
                composable(BeSnapRoutes.MATCHES) {
                    PlaceholderScreen("\uD83D\uDC9C Matches")
                }
                composable(BeSnapRoutes.CHATS) {
                    PlaceholderScreen("\uD83D\uDCAC Chats")
                }
                composable(BeSnapRoutes.PROFILE) {
                    PlaceholderScreen("\uD83D\uDC64 Profile")
                }
            }
        }
    }
}""",
    "app/src/main/kotlin/com/besnap/app/navigation/PlaceholderScreen.kt": """package com.besnap.app.navigation

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier

@Composable
fun PlaceholderScreen(title: String) {
    Box(
        modifier = Modifier.fillMaxSize(),
        contentAlignment = Alignment.Center
    ) {
        Text(
            text = title,
            style = MaterialTheme.typography.headlineLarge
        )
    }
}""",
    "core/common/build.gradle.kts": """plugins {
    alias(libs.plugins.android.library)
    alias(libs.plugins.kotlin.android)
}

android {
    namespace = "com.besnap.core.common"
    compileSdk = 35
    defaultConfig { minSdk = 26 }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions { jvmTarget = "17" }
}

dependencies {
    implementation(libs.kotlinx.coroutines.android)
    implementation(libs.timber)
}""",
    "core/common/src/main/AndroidManifest.xml": """<?xml version="1.0" encoding="utf-8"?>
<manifest />""",
    "core/common/src/main/kotlin/com/besnap/core/common/Result.kt": """package com.besnap.core.common

sealed interface BeSnapResult<out T> {
    data class Success<T>(val data: T) : BeSnapResult<T>
    data class Error(val message: String, val throwable: Throwable? = null) : BeSnapResult<Nothing>
    data object Loading : BeSnapResult<Nothing>
}""",
    "core/common/src/main/kotlin/com/besnap/core/common/Extensions.kt": """package com.besnap.core.common

import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.concurrent.TimeUnit

fun Long.toRelativeTime(): String {
    val now = System.currentTimeMillis()
    val diff = now - this
    return when {
        diff < TimeUnit.MINUTES.toMillis(1) -> "just now"
        diff < TimeUnit.HOURS.toMillis(1) -> "${diff / TimeUnit.MINUTES.toMillis(1)}m"
        diff < TimeUnit.DAYS.toMillis(1) -> "${diff / TimeUnit.HOURS.toMillis(1)}h"
        diff < TimeUnit.DAYS.toMillis(7) -> "${diff / TimeUnit.DAYS.toMillis(1)}d"
        else -> SimpleDateFormat("MMM d", Locale.getDefault()).format(Date(this))
    }
}""",
    "core/design/build.gradle.kts": """plugins {
    alias(libs.plugins.android.library)
    alias(libs.plugins.kotlin.android)
    alias(libs.plugins.kotlin.compose)
}

android {
    namespace = "com.besnap.core.design"
    compileSdk = 35
    defaultConfig { minSdk = 26 }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions { jvmTarget = "17" }
    buildFeatures { compose = true }
}

dependencies {
    api(platform(libs.androidx.compose.bom))
    api(libs.androidx.compose.ui)
    api(libs.androidx.compose.ui.graphics)
    api(libs.androidx.compose.material3)
    api(libs.androidx.compose.material.icons)
    debugApi(libs.androidx.compose.ui.tooling)
    api(libs.androidx.compose.ui.tooling.preview)
}""",
    "core/design/src/main/AndroidManifest.xml": """<?xml version="1.0" encoding="utf-8"?>
<manifest />""",
    "core/design/src/main/kotlin/com/besnap/core/design/theme/Color.kt": """package com.besnap.core.design.theme

import androidx.compose.ui.graphics.Color

// Primary
val Purple80 = Color(0xFFCFBCFF)
val Purple40 = Color(0xFF7B2FBE)
val Purple20 = Color(0xFF4A148C)

// Accent
val Pink80 = Color(0xFFFFB3D9)
val Pink40 = Color(0xFFFF4081)

// Surface
val DarkSurface = Color(0xFF121212)
val DarkSurfaceVariant = Color(0xFF1E1E1E)
val DarkSurfaceHigh = Color(0xFF2C2C2C)

// Functional
val LikeGreen = Color(0xFF4CAF50)
val PassRed = Color(0xFFEF5350)
val SnapYellow = Color(0xFFFFFC00)
val OnlineGreen = Color(0xFF66BB6A)""",
    "core/design/src/main/kotlin/com/besnap/core/design/theme/Type.kt": """package com.besnap.core.design.theme

import androidx.compose.material3.Typography
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.sp

val BeSnapTypography = Typography(
    displayLarge = TextStyle(
        fontWeight = FontWeight.Bold,
        fontSize = 32.sp,
        lineHeight = 40.sp,
    ),
    headlineLarge = TextStyle(
        fontWeight = FontWeight.Bold,
        fontSize = 24.sp,
        lineHeight = 32.sp,
    ),
    headlineMedium = TextStyle(
        fontWeight = FontWeight.SemiBold,
        fontSize = 20.sp,
        lineHeight = 28.sp,
    ),
    titleLarge = TextStyle(
        fontWeight = FontWeight.SemiBold,
        fontSize = 18.sp,
        lineHeight = 24.sp,
    ),
    bodyLarge = TextStyle(
        fontWeight = FontWeight.Normal,
        fontSize = 16.sp,
        lineHeight = 24.sp,
    ),
    bodyMedium = TextStyle(
        fontWeight = FontWeight.Normal,
        fontSize = 14.sp,
        lineHeight = 20.sp,
    ),
    labelLarge = TextStyle(
        fontWeight = FontWeight.SemiBold,
        fontSize = 14.sp,
        lineHeight = 20.sp,
    ),
    labelSmall = TextStyle(
        fontWeight = FontWeight.Medium,
        fontSize = 11.sp,
        lineHeight = 16.sp,
    ),
)""",
    "core/design/src/main/kotlin/com/besnap/core/design/theme/Theme.kt": """package com.besnap.core.design.theme

import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.runtime.Composable

private val DarkColorScheme = darkColorScheme(
    primary = Purple40,
    onPrimary = androidx.compose.ui.graphics.Color.White,
    primaryContainer = Purple20,
    secondary = Pink40,
    onSecondary = androidx.compose.ui.graphics.Color.White,
    background = DarkSurface,
    surface = DarkSurfaceVariant,
    surfaceVariant = DarkSurfaceHigh,
    onBackground = androidx.compose.ui.graphics.Color.White,
    onSurface = androidx.compose.ui.graphics.Color.White,
)

@Composable
fun BeSnapTheme(
    content: @Composable () -> Unit
) {
    MaterialTheme(
        colorScheme = DarkColorScheme,
        typography = BeSnapTypography,
        content = content
    )
}""",
    "core/design/src/main/kotlin/com/besnap/core/design/components/BeSnapButton.kt": """package com.besnap.core.design.components

import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp

@Composable
fun BeSnapButton(
    text: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    enabled: Boolean = true,
) {
    Button(
        onClick = onClick,
        modifier = modifier.fillMaxWidth().height(52.dp),
        enabled = enabled,
        shape = RoundedCornerShape(26.dp),
    ) {
        Text(text = text, style = MaterialTheme.typography.labelLarge)
    }
}

@Composable
fun BeSnapOutlinedButton(
    text: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    enabled: Boolean = true,
) {
    OutlinedButton(
        onClick = onClick,
        modifier = modifier.fillMaxWidth().height(52.dp),
        enabled = enabled,
        shape = RoundedCornerShape(26.dp),
    ) {
        Text(text = text, style = MaterialTheme.typography.labelLarge)
    }
}

@Composable
fun BeSnapTextButton(
    text: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
) {
    TextButton(onClick = onClick, modifier = modifier) {
        Text(text = text, style = MaterialTheme.typography.labelLarge)
    }
}""",
    "core/design/src/main/kotlin/com/besnap/core/design/components/InterestChip.kt": """package com.besnap.core.design.components

import androidx.compose.foundation.layout.padding
import androidx.compose.material3.FilterChip
import androidx.compose.material3.FilterChipDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp

@Composable
fun InterestChip(
    emoji: String,
    label: String,
    selected: Boolean,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
) {
    FilterChip(
        selected = selected,
        onClick = onClick,
        label = {
            Text(
                text = "$emoji $label",
                style = MaterialTheme.typography.bodyMedium,
            )
        },
        modifier = modifier.padding(end = 8.dp, bottom = 4.dp),
    )
}""",
    "core/network/build.gradle.kts": """plugins {
    alias(libs.plugins.android.library)
    alias(libs.plugins.kotlin.android)
    alias(libs.plugins.hilt)
    alias(libs.plugins.ksp)
}

android {
    namespace = "com.besnap.core.network"
    compileSdk = 35
    defaultConfig { minSdk = 26 }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions { jvmTarget = "17" }
}

dependencies {
    implementation(project(":core:common"))

    implementation(libs.retrofit)
    implementation(libs.retrofit.moshi)
    implementation(libs.okhttp)
    implementation(libs.okhttp.logging)
    implementation(libs.moshi)
    ksp(libs.moshi.codegen)

    implementation(libs.hilt.android)
    ksp(libs.hilt.compiler)
    implementation(libs.timber)
}""",
    "core/network/src/main/AndroidManifest.xml": """<?xml version="1.0" encoding="utf-8"?>
<manifest />""",
    "core/network/src/main/kotlin/com/besnap/core/network/AuthInterceptor.kt": """package com.besnap.core.network

import okhttp3.Interceptor
import okhttp3.Response
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class AuthInterceptor @Inject constructor(
    private val tokenProvider: TokenProvider,
) : Interceptor {
    override fun intercept(chain: Interceptor.Chain): Response {
        val request = chain.request()
        val token = tokenProvider.getAccessToken()
        return if (token != null) {
            val authenticatedRequest = request.newBuilder()
                .header("Authorization", "Bearer $token")
                .build()
            chain.proceed(authenticatedRequest)
        } else {
            chain.proceed(request)
        }
    }
}

interface TokenProvider {
    fun getAccessToken(): String?
    fun setAccessToken(token: String?)
}""",
    "core/network/src/main/kotlin/com/besnap/core/network/NetworkModule.kt": """package com.besnap.core.network

import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.components.SingletonComponent
import okhttp3.OkHttpClient
import okhttp3.logging.HttpLoggingInterceptor
import retrofit2.Retrofit
import retrofit2.converter.moshi.MoshiConverterFactory
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
object NetworkModule {

    @Provides
    @Singleton
    fun provideOkHttpClient(authInterceptor: AuthInterceptor): OkHttpClient {
        return OkHttpClient.Builder()
            .addInterceptor(authInterceptor)
            .addInterceptor(
                HttpLoggingInterceptor().apply {
                    level = HttpLoggingInterceptor.Level.BODY
                }
            )
            .build()
    }

    @Provides
    @Singleton
    fun provideRetrofit(okHttpClient: OkHttpClient): Retrofit {
        return Retrofit.Builder()
            .baseUrl("http://10.0.2.2:3000/v1/")
            .client(okHttpClient)
            .addConverterFactory(MoshiConverterFactory.create())
            .build()
    }
}""",
    "core/network/src/main/kotlin/com/besnap/core/network/BeSnapApi.kt": """package com.besnap.core.network

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
}""",
    "core/network/src/main/kotlin/com/besnap/core/network/model/AuthModels.kt": """package com.besnap.core.network.model

import com.squareup.moshi.JsonClass

@JsonClass(generateAdapter = true)
data class RegisterRequest(
    val email: String,
    val password: String,
    val displayName: String,
    val dateOfBirth: String,
)

@JsonClass(generateAdapter = true)
data class LoginRequest(
    val email: String,
    val password: String,
)

@JsonClass(generateAdapter = true)
data class AuthResponse(
    val accessToken: String,
)""",
    "core/network/src/main/kotlin/com/besnap/core/network/model/UserModels.kt": """package com.besnap.core.network.model

import com.squareup.moshi.JsonClass

@JsonClass(generateAdapter = true)
data class UserResponse(
    val id: String,
    val email: String?,
    val phone: String?,
    val onboardingDone: Boolean,
    val profile: ProfileDto?,
)

@JsonClass(generateAdapter = true)
data class ProfileDto(
    val id: String,
    val displayName: String,
    val bio: String,
    val gender: String,
    val lookingFor: String,
    val verified: Boolean,
)

@JsonClass(generateAdapter = true)
data class InterestDto(
    val id: String,
    val slug: String,
    val label: String,
    val emoji: String,
)""",
    "core/network/src/main/kotlin/com/besnap/core/network/ApiModule.kt": """package com.besnap.core.network

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
}""",
    "core/auth/build.gradle.kts": """plugins {
    alias(libs.plugins.android.library)
    alias(libs.plugins.kotlin.android)
    alias(libs.plugins.hilt)
    alias(libs.plugins.ksp)
}

android {
    namespace = "com.besnap.core.auth"
    compileSdk = 35
    defaultConfig { minSdk = 26 }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions { jvmTarget = "17" }
}

dependencies {
    implementation(project(":core:common"))
    implementation(project(":core:network"))

    implementation(libs.security.crypto)
    implementation(libs.hilt.android)
    ksp(libs.hilt.compiler)
    implementation(libs.kotlinx.coroutines.android)
    implementation(libs.timber)
}""",
    "core/auth/src/main/AndroidManifest.xml": """<?xml version="1.0" encoding="utf-8"?>
<manifest />""",
    "core/auth/src/main/kotlin/com/besnap/core/auth/SessionManager.kt": """package com.besnap.core.auth

import android.content.Context
import androidx.security.crypto.EncryptedSharedPreferences
import androidx.security.crypto.MasterKey
import com.besnap.core.network.TokenProvider
import dagger.hilt.android.qualifiers.ApplicationContext
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class SessionManager @Inject constructor(
    @ApplicationContext context: Context,
) : TokenProvider {

    private val masterKey = MasterKey.Builder(context)
        .setKeyScheme(MasterKey.KeyScheme.AES256_GCM)
        .build()

    private val prefs = EncryptedSharedPreferences.create(
        context,
        "besnap_session",
        masterKey,
        EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
        EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM,
    )

    override fun getAccessToken(): String? = prefs.getString(KEY_ACCESS_TOKEN, null)

    override fun setAccessToken(token: String?) {
        prefs.edit().putString(KEY_ACCESS_TOKEN, token).apply()
    }

    val isLoggedIn: Boolean get() = getAccessToken() != null

    fun logout() {
        prefs.edit().clear().apply()
    }

    companion object {
        private const val KEY_ACCESS_TOKEN = "access_token"
    }
}""",
    "core/auth/src/main/kotlin/com/besnap/core/auth/AuthModule.kt": """package com.besnap.core.auth

import com.besnap.core.network.TokenProvider
import dagger.Binds
import dagger.Module
import dagger.hilt.InstallIn
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
abstract class AuthModule {

    @Binds
    @Singleton
    abstract fun bindTokenProvider(sessionManager: SessionManager): TokenProvider
}""",
    "core/database/build.gradle.kts": """plugins {
    alias(libs.plugins.android.library)
    alias(libs.plugins.kotlin.android)
    alias(libs.plugins.ksp)
}

android {
    namespace = "com.besnap.core.database"
    compileSdk = 35
    defaultConfig { minSdk = 26 }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions { jvmTarget = "17" }
}

dependencies {
    implementation(libs.room.runtime)
    implementation(libs.room.ktx)
    ksp(libs.room.compiler)
}""",
    "core/database/src/main/AndroidManifest.xml": """<?xml version="1.0" encoding="utf-8"?>
<manifest />""",
    "core/database/src/main/kotlin/com/besnap/core/database/BeSnapDatabase.kt": """package com.besnap.core.database

import androidx.room.Database
import androidx.room.RoomDatabase

@Database(entities = [], version = 1, exportSchema = false)
abstract class BeSnapDatabase : RoomDatabase()""",
    "core/media/build.gradle.kts": """plugins {
    alias(libs.plugins.android.library)
    alias(libs.plugins.kotlin.android)
}

android {
    namespace = "com.besnap.core.media"
    compileSdk = 35
    defaultConfig { minSdk = 26 }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions { jvmTarget = "17" }
}

dependencies {
    implementation(project(":core:common"))
    implementation(libs.kotlinx.coroutines.android)
    implementation(libs.timber)
}""",
    "core/media/src/main/AndroidManifest.xml": """<?xml version="1.0" encoding="utf-8"?>
<manifest />""",
    "core/media/src/main/kotlin/com/besnap/core/media/MediaCompressor.kt": """package com.besnap.core.media

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
}""",
    "core/permissions/build.gradle.kts": """plugins {
    alias(libs.plugins.android.library)
    alias(libs.plugins.kotlin.android)
    alias(libs.plugins.kotlin.compose)
}

android {
    namespace = "com.besnap.core.permissions"
    compileSdk = 35
    defaultConfig { minSdk = 26 }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions { jvmTarget = "17" }
    buildFeatures { compose = true }
}

dependencies {
    implementation(project(":core:design"))
    implementation(platform(libs.androidx.compose.bom))
    implementation(libs.androidx.compose.ui)
    implementation(libs.androidx.compose.material3)
    implementation(libs.androidx.activity.compose)
}""",
    "core/permissions/src/main/AndroidManifest.xml": """<?xml version="1.0" encoding="utf-8"?>
<manifest />""",
    "core/permissions/src/main/kotlin/com/besnap/core/permissions/PermissionManager.kt": """package com.besnap.core.permissions

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
}"""
}

feature_modules = [
    "onboarding", "discover", "matches", "chat", 
    "camera", "calls", "profile", "notifications", "safety"
]

for feature in feature_modules:
    files[f"feature/{feature}/build.gradle.kts"] = f"""plugins {{
    alias(libs.plugins.android.library)
    alias(libs.plugins.kotlin.android)
    alias(libs.plugins.kotlin.compose)
    alias(libs.plugins.hilt)
    alias(libs.plugins.ksp)
}}

android {{
    namespace = "com.besnap.feature.{feature}"
    compileSdk = 35
    defaultConfig {{ minSdk = 26 }}
    compileOptions {{
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }}
    kotlinOptions {{ jvmTarget = "17" }}
    buildFeatures {{ compose = true }}
}}

dependencies {{
    implementation(project(":core:common"))
    implementation(project(":core:design"))
    implementation(project(":core:network"))

    implementation(platform(libs.androidx.compose.bom))
    implementation(libs.androidx.compose.ui)
    implementation(libs.androidx.compose.material3)
    implementation(libs.androidx.navigation.compose)
    implementation(libs.androidx.hilt.navigation.compose)
    implementation(libs.androidx.lifecycle.viewmodel.compose)

    implementation(libs.hilt.android)
    ksp(libs.hilt.compiler)
    implementation(libs.timber)
}}"""
    
    files[f"feature/{feature}/src/main/AndroidManifest.xml"] = """<?xml version="1.0" encoding="utf-8"?>
<manifest />"""
    
    files[f"feature/{feature}/src/main/kotlin/com/besnap/feature/{feature}/PlaceholderNav.kt"] = f"""package com.besnap.feature.{feature}

// Feature module placeholder — implementation coming in later phases"""

for filepath, content in files.items():
    full_path = os.path.join(workspace, filepath)
    os.makedirs(os.path.dirname(full_path), exist_ok=True)
    with open(full_path, "w", encoding="utf-8") as f:
        f.write(content)

print(f"Created {len(files)} files successfully.")
