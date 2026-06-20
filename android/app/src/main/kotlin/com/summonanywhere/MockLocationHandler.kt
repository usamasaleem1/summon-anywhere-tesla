package com.summonanywhere

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.location.Criteria
import android.location.Location
import android.location.LocationManager
import android.net.Uri
import android.os.Build
import android.os.SystemClock
import android.provider.Settings
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

object MockLocationHandler {
    private const val CHANNEL_NAME = "com.summonanywhere/mock_location"

    private lateinit var appContext: Context
    private var locationManager: LocationManager? = null
    private var mockProviderActive = false
    private var activity: Activity? = null

    private var initialized = false

    fun init(context: Context) {
        if (initialized) return
        initialized = true
        appContext = context.applicationContext
        locationManager =
            appContext.getSystemService(Context.LOCATION_SERVICE) as LocationManager
    }

    fun setActivity(activity: Activity?) {
        this.activity = activity
    }

    fun register(flutterEngine: FlutterEngine) {
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_NAME)
            .setMethodCallHandler { call, result ->
                try {
                    when (call.method) {
                        "enableMockProvider" -> {
                            enableMockProvider()
                            result.success(true)
                        }
                        "disableMockProvider" -> {
                            disableMockProvider()
                            result.success(true)
                        }
                        "updateLocation" -> {
                            val lat = call.argument<Double>("latitude")
                            val lng = call.argument<Double>("longitude")
                            if (lat == null || lng == null) {
                                result.error(
                                    "INVALID_ARGS",
                                    "latitude and longitude required",
                                    null,
                                )
                                return@setMethodCallHandler
                            }
                            updateLocation(lat, lng)
                            result.success(true)
                        }
                        "isEnabled" -> {
                            result.success(isMockLocationEnabled())
                        }
                        "openDeveloperSettings" -> {
                            val host = activity
                            if (host == null) {
                                result.error(
                                    "NO_ACTIVITY",
                                    "Activity not available",
                                    null,
                                )
                                return@setMethodCallHandler
                            }
                            host.startActivity(
                                Intent(Settings.ACTION_APPLICATION_DEVELOPMENT_SETTINGS),
                            )
                            result.success(true)
                        }
                        "openBatterySettings" -> {
                            val host = activity
                            if (host == null) {
                                result.error(
                                    "NO_ACTIVITY",
                                    "Activity not available",
                                    null,
                                )
                                return@setMethodCallHandler
                            }
                            val intent =
                                Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
                                    data = Uri.parse("package:${appContext.packageName}")
                                }
                            host.startActivity(intent)
                            result.success(true)
                        }
                        else -> result.notImplemented()
                    }
                } catch (e: Exception) {
                    result.error("MOCK_LOCATION_ERROR", e.message, null)
                }
            }
    }

    private fun enableMockProvider() {
        val lm = locationManager ?: return
        try {
            lm.removeTestProvider(LocationManager.GPS_PROVIDER)
        } catch (_: Exception) {
        }

        lm.addTestProvider(
            LocationManager.GPS_PROVIDER,
            false,
            false,
            false,
            false,
            false,
            true,
            true,
            Criteria.POWER_LOW,
            Criteria.ACCURACY_FINE,
        )
        lm.setTestProviderEnabled(LocationManager.GPS_PROVIDER, true)
        mockProviderActive = true
    }

    private fun disableMockProvider() {
        val lm = locationManager ?: return
        try {
            lm.setTestProviderEnabled(LocationManager.GPS_PROVIDER, false)
            lm.removeTestProvider(LocationManager.GPS_PROVIDER)
        } catch (_: Exception) {
        }
        mockProviderActive = false
    }

    private fun updateLocation(latitude: Double, longitude: Double) {
        val lm = locationManager ?: return
        if (!mockProviderActive) {
            enableMockProvider()
        }

        val location = Location(LocationManager.GPS_PROVIDER).apply {
            this.latitude = latitude
            this.longitude = longitude
            accuracy = 1f
            altitude = 0.0
            time = System.currentTimeMillis()
            elapsedRealtimeNanos = SystemClock.elapsedRealtimeNanos()
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                bearing = 0f
                speed = 0f
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                isMock = true
            }
        }

        lm.setTestProviderLocation(LocationManager.GPS_PROVIDER, location)
    }

    private fun isMockLocationEnabled(): Boolean {
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                val appOps =
                    appContext.getSystemService(Context.APP_OPS_SERVICE) as android.app.AppOpsManager
                @Suppress("DEPRECATION")
                appOps.checkOpNoThrow(
                    android.app.AppOpsManager.OPSTR_MOCK_LOCATION,
                    android.os.Process.myUid(),
                    appContext.packageName,
                ) == android.app.AppOpsManager.MODE_ALLOWED
            } else {
                @Suppress("DEPRECATION")
                Settings.Secure.getString(
                    appContext.contentResolver,
                    Settings.Secure.ALLOW_MOCK_LOCATION,
                ) != "0"
            }
        } catch (_: Exception) {
            false
        }
    }
}
