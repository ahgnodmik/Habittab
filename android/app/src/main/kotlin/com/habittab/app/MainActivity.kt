package com.habittab.app

import io.flutter.embedding.android.FlutterActivity
import android.os.Bundle

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // HomeWidgetProvider 관련 코드 삭제
    }

    override fun onNewIntent(intent: android.content.Intent) {
        super.onNewIntent(intent)
        // HomeWidgetProvider 관련 코드 삭제
    }
}
