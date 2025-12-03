package com.example.app_navegacion_offline.data

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query

@Dao
interface FavoriteRouteDao {
    @Query("SELECT * FROM favorite_routes ORDER BY id DESC")
    fun getRoutes(): List<FavoriteRouteEntity>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    fun insertAll(routes: List<FavoriteRouteEntity>)

    @Query("DELETE FROM favorite_routes")
    fun clear()
}
