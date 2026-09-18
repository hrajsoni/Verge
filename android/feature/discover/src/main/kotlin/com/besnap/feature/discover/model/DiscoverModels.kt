package com.besnap.feature.discover.model

data class DiscoverCard(
    val userId: String,
    val displayName: String,
    val age: Int,
    val distanceLabel: String,
    val bio: String,
    val interests: List<String>, // format: "emoji label"
    val photos: List<String>,
    val lookingFor: String
)

enum class SwipeDirection {
    LEFT, RIGHT
}
