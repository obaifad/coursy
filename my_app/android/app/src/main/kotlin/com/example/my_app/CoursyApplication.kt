package com.example.my_app

import android.app.Application
import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build

class CoursyApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        createDefaultNotificationChannel()
    }

    private fun createDefaultNotificationChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return

        val channel = NotificationChannel(
            MainActivity.CHANNEL_ID,
            MainActivity.CHANNEL_NAME,
            NotificationManager.IMPORTANCE_HIGH,
        ).apply {
            description = "Coursy notifications"
            enableVibration(true)
            enableLights(true)
            setShowBadge(true)
        }

        getSystemService(NotificationManager::class.java)?.createNotificationChannel(channel)
    }
}
