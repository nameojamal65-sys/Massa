#!/bin/bash
# 🚀 Legendary v6 FullStack APK Builder

# ===================== مسارات المشروع =====================
BASE="$HOME/Legendary_Dashboard/v6"
ANDROID_PROJECT="$HOME/Legendary_v6_APK"
BACKEND="$BASE/backend"
FRONTEND="$BASE/frontend/build"
PORT=9000
FRONT_PORT=3000

# ===================== إعداد المشروع =====================
echo "📦 إعداد مشروع Android جديد..."
mkdir -p "$ANDROID_PROJECT"
cd "$ANDROID_PROJECT"

mkdir -p app/src/main/{java/com/legendaryv6,assets,python,res/layout}

# ===================== نسخ ملفات Frontend =====================
echo "🌐 نسخ ملفات Frontend React..."
if [ -d "$FRONTEND" ]; then
    cp -r "$FRONTEND"/* app/src/main/assets/
else
    echo "⚠️ مجلد Frontend build غير موجود! تأكد من بناء React frontend أولاً."
fi

# ===================== نسخ ملفات Backend =====================
echo "🧠 نسخ Backend Python..."
cp -r "$BACKEND"/* app/src/main/python/

# ===================== MainActivity.kt =====================
cat > app/src/main/java/com/legendaryv6/MainActivity.kt << 'EOF'
package com.legendaryv6

import android.os.Bundle
import android.webkit.WebView
import android.webkit.WebViewClient
import androidx.appcompat.app.AppCompatActivity
import com.chaquo.python.Python
import com.chaquo.python.android.AndroidPlatform

class MainActivity : AppCompatActivity() {
    private lateinit var webView: WebView

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        if (!Python.isStarted()) {
            Python.start(AndroidPlatform(this))
        }
        val py = Python.getInstance()
        py.getModule("main") // Backend main.py

        webView = findViewById(R.id.webview)
        webView.webViewClient = WebViewClient()
        webView.settings.javaScriptEnabled = true
        webView.loadUrl("file:///android_asset/index.html")
    }
}
EOF

# ===================== layout XML =====================
cat > app/src/main/res/layout/activity_main.xml << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<RelativeLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="match_parent">

    <WebView
        android:id="@+id/webview"
        android:layout_width="match_parent"
        android:layout_height="match_parent"/>
</RelativeLayout>
EOF

# ===================== AndroidManifest.xml =====================
cat > app/src/main/AndroidManifest.xml << 'EOF'
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.legendaryv6">

    <uses-permission android:name="android.permission.INTERNET"/>

    <application
        android:label="Legendary Dashboard v6"
        android:theme="@style/Theme.AppCompat.Light.NoActionBar">
        <activity android:name=".MainActivity"
            android:exported="true">
            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
        </activity>
    </application>
</manifest>
EOF

# ===================== build.gradle =====================
cat > app/build.gradle << 'EOF'
plugins {
    id 'com.android.application'
    id 'com.chaquo.python'
}

android {
    compileSdk 33
    defaultConfig {
        applicationId "com.legendaryv6"
        minSdk 21
        targetSdk 33
        versionCode 1
        versionName "1.0"
    }
}

python {
    pip {
        install "fastapi"
        install "uvicorn"
        install "psutil"
        install "aiosqlite"
    }
}
EOF

# ===================== الانتهاء =====================
echo "✅ مشروع Android جاهز!"
echo "📂 المسار: $ANDROID_PROJECT"
echo "🔥 بعد فتح المشروع: Build → Build APK(s) → Build APK(s) في Android Studio"
