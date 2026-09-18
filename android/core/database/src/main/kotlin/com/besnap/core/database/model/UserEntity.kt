package com.besnap.core.database.model

import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity(tableName = "users")
data class UserEntity(
    @PrimaryKey val id: String,
    val displayName: String,
    val email: String? = null,
    val bio: String = "",
    val updatedAt: Long = System.currentTimeMillis(),
)
