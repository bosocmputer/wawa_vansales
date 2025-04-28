package com.example.wawa_vansales

import android.os.Bundle
import android.util.Log
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Filter out IMGMapper warnings from logcat
        try {
            val process = Runtime.getRuntime().exec("logcat -c")
            process.waitFor()
            Runtime.getRuntime().exec("logcat IMGMapper:S *:V")
        } catch (e: Exception) {
            Log.e("MainActivity", "Failed to filter logcat: ${e.message}")
        }
    }
}
