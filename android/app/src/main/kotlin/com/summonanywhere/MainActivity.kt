package com.summonanywhere

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MockLocationHandler.init(applicationContext)
        MockLocationHandler.setActivity(this)
        MockLocationHandler.register(flutterEngine)
    }

    override fun onResume() {
        super.onResume()
        MockLocationHandler.setActivity(this)
    }

    override fun onPause() {
        MockLocationHandler.setActivity(null)
        super.onPause()
    }
}
