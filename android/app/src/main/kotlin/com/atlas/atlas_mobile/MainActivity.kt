package com.atlas.atlas_mobile

import android.content.Intent
import android.net.Uri
import android.provider.Settings
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Lesson screens turn on FLAG_SECURE: Android then shows a black frame
        // to screenshots, screen recorders, casting and the recents preview.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "atlas/screen_protection")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "setSecure" -> {
                        val on = call.arguments as? Boolean ?: false
                        runOnUiThread {
                            if (on) {
                                window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
                            } else {
                                window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                            }
                            result.success(true)
                        }
                    }
                    "isCaptured" -> result.success(false)
                    else -> result.notImplemented()
                }
            }
        // "Open settings" where a permission was refused (the QR camera).
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "atlas/app_settings")
            .setMethodCallHandler { call, result ->
                if (call.method == "open") {
                    val intent = Intent(
                        Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                        Uri.fromParts("package", packageName, null),
                    ).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    result.success(runCatching { startActivity(intent) }.isSuccess)
                } else {
                    result.notImplemented()
                }
            }
    }
}
