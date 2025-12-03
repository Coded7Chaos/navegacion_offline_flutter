package com.example.app_navegacion_offline

import com.example.app_navegacion_offline.data.AppDatabase
import com.example.app_navegacion_offline.data.UserProfileEntity
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
    private val DB_CHANNEL = "com.example.app_navegacion_offline/db"
    private val ioExecutor = Executors.newSingleThreadExecutor()

    private lateinit var database: AppDatabase

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        database = AppDatabase.getDatabase(applicationContext)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, DB_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getFavorites" -> ioExecutor.execute {
                    try {
                        val routes = database.favoriteRouteDao().getRoutes()
                        val mapped = routes.map {
                            mapOf(
                                "id" to it.id,
                                "title" to it.title,
                                "description" to it.description
                            )
                        }
                        runOnUiThread { result.success(mapped) }
                    } catch (e: Exception) {
                        runOnUiThread { result.error("DB_ERROR", e.message, null) }
                    }
                }
                "getUserProfile" -> ioExecutor.execute {
                    try {
                        val profile = database.userProfileDao().getProfile()
                        val mapped = profile?.let {
                            mapOf(
                                "id" to it.id,
                                "name" to it.name,
                                "email" to it.email
                            )
                        }
                        runOnUiThread { result.success(mapped) }
                    } catch (e: Exception) {
                        runOnUiThread { result.error("DB_ERROR", e.message, null) }
                    }
                }
                "saveUserProfile" -> {
                    val name = call.argument<String>("name")
                    val email = call.argument<String>("email")
                    ioExecutor.execute {
                        try {
                            val profile = UserProfileEntity(name = name ?: "Invitado", email = email ?: "", id = 0)
                            database.userProfileDao().saveProfile(profile)
                            runOnUiThread { result.success(true) }
                        } catch (e: Exception) {
                            runOnUiThread { result.error("DB_ERROR", e.message, null) }
                        }
                    }
                }
                else -> result.notImplemented()
            }
        }
    }
}
