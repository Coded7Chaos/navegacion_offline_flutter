package com.example.app_navegacion_offline.data

import android.content.Context
import androidx.room.Database
import androidx.room.Room
import androidx.room.RoomDatabase
import androidx.sqlite.db.SupportSQLiteDatabase

@Database(
    entities = [FavoriteRouteEntity::class, UserProfileEntity::class],
    version = 1,
    exportSchema = false
)
abstract class AppDatabase : RoomDatabase() {
    abstract fun favoriteRouteDao(): FavoriteRouteDao
    abstract fun userProfileDao(): UserProfileDao

    companion object {
        @Volatile
        private var INSTANCE: AppDatabase? = null

        fun getDatabase(context: Context): AppDatabase {
            return INSTANCE ?: synchronized(this) {
                val instance = Room.databaseBuilder(
                    context.applicationContext,
                    AppDatabase::class.java,
                    "navigation_app.db"
                )
                    .addCallback(object : RoomDatabase.Callback() {
                        override fun onCreate(db: SupportSQLiteDatabase) {
                            super.onCreate(db)
                            db.execSQL(
                                "INSERT INTO favorite_routes (title, description) VALUES ('Miraflores panorámica', 'Ruta guardada hacia Miraflores con tráfico moderado')"
                            )
                            db.execSQL(
                                "INSERT INTO favorite_routes (title, description) VALUES ('Achumani rápido', 'Atajo favorito para llegar a San Pedro en menos de 25 minutos')"
                            )
                        }
                    })
                    .build()
                INSTANCE = instance
                instance
            }
        }
    }
}
