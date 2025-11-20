package com.example.fiapp

import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.skorcard.fiapp/screenshot"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Set up method channel for screenshot protection (DISABLED)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "disableScreenshot" -> {
                    // Screenshot protection is disabled - allow screenshots
                    // disableScreenshot()
                    result.success(true)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Enable screenshot - Comment out FLAG_SECURE
        // disableScreenshot()
    }

    private fun disableScreenshot() {
        // FLAG_SECURE prevents screenshots and screen recording (DISABLED)
        // Allow screenshots by commenting out FLAG_SECURE
        // window.setFlags(
        //     WindowManager.LayoutParams.FLAG_SECURE,
        //     WindowManager.LayoutParams.FLAG_SECURE
        // )
    }
}
