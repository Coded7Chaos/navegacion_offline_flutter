package com.example.app_navegacion_offline.data

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query

@Dao
interface UserProfileDao {
    @Query("SELECT * FROM user_profile LIMIT 1")
    fun getProfile(): UserProfileEntity?

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    fun saveProfile(profile: UserProfileEntity)
}
