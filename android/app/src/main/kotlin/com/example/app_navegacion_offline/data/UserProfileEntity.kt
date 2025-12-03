package com.example.app_navegacion_offline.data

import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity(tableName = "user_profile")
data class UserProfileEntity(
    @PrimaryKey val id: Int = 0,
    val name: String,
    val email: String
)
