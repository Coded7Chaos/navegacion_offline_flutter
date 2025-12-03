package com.example.app_navegacion_offline.data

import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity(tableName = "favorite_routes")
data class FavoriteRouteEntity(
    @PrimaryKey(autoGenerate = true) val id: Int = 0,
    val title: String,
    val description: String
)
