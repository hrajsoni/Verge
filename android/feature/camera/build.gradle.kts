plugins {
    alias(libs.plugins.android.library)
    alias(libs.plugins.kotlin.android)
    alias(libs.plugins.kotlin.compose)
    alias(libs.plugins.hilt)
    alias(libs.plugins.ksp)
}

android {
    namespace = "com.besnap.feature.camera"
    compileSdk = 35
    defaultConfig { 
        minSdk = 26 
        buildConfigField("String", "CAMERA_KIT_API_TOKEN_STAGING", "\"eyJhbGciOiJIUzI1NiIsImtpZCI6IkNhbnZhc1MyU0hNQUNQcm9kIiwidHlwIjoiSldUIn0.eyJhdWQiOiJjYW52YXMtY2FudmFzYXBpIiwiaXNzIjoiY2FudmFzLXMyc3Rva2VuIiwibmJmIjoxNzg5OTAwNDU1LCJzdWIiOiI1ZWIxODVjNC1mOTE0LTQwYTItYjM4Ny1lY2M0NWViNjI4ZTR-U1RBR0lOR35jZWI5YThlOS03NDEzLTQ1NjYtOWJlZC05OGQ2OWFjNDYwMTkifQ.mEzFOB26ISCZ6tjDxoRFTWLw7wNVd4jx0kebS4j3z_Y\"")
        buildConfigField("String", "CAMERA_KIT_API_TOKEN_PRODUCTION", "\"eyJhbGciOiJIUzI1NiIsImtpZCI6IkNhbnZhc1MyU0hNQUNQcm9kIiwidHlwIjoiSldUIn0.eyJhdWQiOiJjYW52YXMtY2FudmFzYXBpIiwiaXNzIjoiY2FudmFzLXMyc3Rva2VuIiwibmJmIjoxNzg5OTAwNDU1LCJzdWIiOiI1ZWIxODVjNC1mOTE0LTQwYTItYjM4Ny1lY2M0NWViNjI4ZTR-UFJPRFVDVElPTn5hMTg4Yzk5My04YmFkLTRjZTktYTA1MC1kMDhiMTE5NDk4MDgifQ.cpRhpS6VOj4h9ols-JAg-WAF4qWGOpTfCPXTCUWP_68\"")
        buildConfigField("String", "CAMERA_KIT_LENS_GROUP_ID", "\"c69c750f-1d67-45fe-8422-bb6212113e58\"")
        manifestPlaceholders["CAMERA_KIT_API_TOKEN"] = "eyJhbGciOiJIUzI1NiIsImtpZCI6IkNhbnZhc1MyU0hNQUNQcm9kIiwidHlwIjoiSldUIn0.eyJhdWQiOiJjYW52YXMtY2FudmFzYXBpIiwiaXNzIjoiY2FudmFzLXMyc3Rva2VuIiwibmJmIjoxNzg5OTAwNDU1LCJzdWIiOiI1ZWIxODVjNC1mOTE0LTQwYTItYjM4Ny1lY2M0NWViNjI4ZTR-U1RBR0lOR35jZWI5YThlOS03NDEzLTQ1NjYtOWJlZC05OGQ2OWFjNDYwMTkifQ.mEzFOB26ISCZ6tjDxoRFTWLw7wNVd4jx0kebS4j3z_Y"
    }
    buildTypes {
        release {
            manifestPlaceholders["CAMERA_KIT_API_TOKEN"] = "eyJhbGciOiJIUzI1NiIsImtpZCI6IkNhbnZhc1MyU0hNQUNQcm9kIiwidHlwIjoiSldUIn0.eyJhdWQiOiJjYW52YXMtY2FudmFzYXBpIiwiaXNzIjoiY2FudmFzLXMyc3Rva2VuIiwibmJmIjoxNzg5OTAwNDU1LCJzdWIiOiI1ZWIxODVjNC1mOTE0LTQwYTItYjM4Ny1lY2M0NWViNjI4ZTR-UFJPRFVDVElPTn5hMTg4Yzk5My04YmFkLTRjZTktYTA1MC1kMDhiMTE5NDk4MDgifQ.cpRhpS6VOj4h9ols-JAg-WAF4qWGOpTfCPXTCUWP_68"
        }
    }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions { jvmTarget = "17" }
    buildFeatures { 
        compose = true 
        buildConfig = true
    }
}

dependencies {
    implementation(project(":core:common"))
    implementation(project(":core:design"))
    implementation(project(":core:network"))
    implementation(project(":core:media"))
    implementation(project(":core:permissions"))

    implementation(platform(libs.androidx.compose.bom))
    implementation(libs.androidx.compose.ui)
    implementation(libs.androidx.compose.material3)
    implementation(libs.androidx.compose.material.icons)
    implementation(libs.androidx.navigation.compose)
    implementation(libs.androidx.hilt.navigation.compose)
    implementation(libs.androidx.lifecycle.viewmodel.compose)

    implementation(libs.androidx.camera.core)
    implementation(libs.androidx.camera.camera2)
    implementation(libs.androidx.camera.lifecycle)
    implementation(libs.androidx.camera.view)

    implementation(libs.coil.compose)

    implementation(libs.hilt.android)
    ksp(libs.hilt.compiler)
    implementation(libs.timber)
    
    // Snap Camera Kit
    implementation("com.snap.camerakit:camerakit:1.12.0")
    implementation("com.snap.camerakit:camerakit-kotlin:1.12.0")
    implementation("com.snap.camerakit:support-camerax:1.12.0")
    implementation("com.snap.camerakit:support-camera-layout:1.12.0")
    // AppCompat required by Camera Kit
    implementation("androidx.appcompat:appcompat:1.7.0")
}
