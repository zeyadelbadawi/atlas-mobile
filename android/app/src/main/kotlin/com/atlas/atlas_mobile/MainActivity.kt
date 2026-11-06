package com.atlas.atlas_mobile

import android.app.ActivityManager
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import android.view.WindowManager
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// A FragmentActivity: the optional app lock (local_auth) shows the
// system's biometric prompt as a fragment.
class MainActivity : FlutterFragmentActivity() {
    // Lessons and quizzes each ask for the secure flag; it stays on while any
    // of them is open (a quiz opened from a lesson must not clear it).
    private var secureHolds = 0

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
                            secureHolds = if (on) secureHolds + 1 else maxOf(0, secureHolds - 1)
                            if (secureHolds > 0) {
                                window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
                            } else {
                                window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                            }
                            result.success(true)
                        }
                    }
                    "isCaptured" -> result.success(false)
                    // Quiz: other apps' floating windows (chat heads, assistant
                    // bubbles) are not drawn over the app. Android 12 and later.
                    "setHideOverlays" -> {
                        val on = call.arguments as? Boolean ?: false
                        runOnUiThread {
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                                window.setHideOverlayWindows(on)
                                result.success(true)
                            } else {
                                result.success(false)
                            }
                        }
                    }
                    // Quiz: screen pinning. Android asks the learner to confirm
                    // and lets them unpin; the app watches the state.
                    "startPin" -> runOnUiThread {
                        result.success(runCatching { startLockTask() }.isSuccess)
                    }
                    "stopPin" -> runOnUiThread {
                        if (pinned()) runCatching { stopLockTask() }
                        result.success(true)
                    }
                    "isPinned" -> result.success(pinned())
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

    private fun pinned(): Boolean {
        val am = getSystemService(ACTIVITY_SERVICE) as ActivityManager
        return am.lockTaskModeState != ActivityManager.LOCK_TASK_MODE_NONE
    }
}
