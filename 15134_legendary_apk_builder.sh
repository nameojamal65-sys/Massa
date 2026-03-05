#!/bin/bash
# 🚀 Legendary v6 FullStack APK Builder - مصحح
# ==========================================

# مسارات المشروع
BASE="$HOME/Legendary_Dashboard/v6"
ANDROID_PROJECT="$HOME/Legendary_v6_APK"
BACKEND="$BASE/backend"
FRONTEND="$BASE/frontend"

# مجلدات Android
APP_DIR="$ANDROID_PROJECT/app"
JAVA_DIR="$APP_DIR/src/main/java/com/legendaryv6"
RES_DIR="$APP_DIR/src/main/res/layout"
ASSETS_DIR="$APP_DIR/src/main/assets"
PYTHON_DIR="$APP_DIR/src/main/python"

echo "📦 إعداد مشروع Android جديد..."
mkdir -p "$JAVA_DIR" "$RES_DIR" "$ASSETS_DIR" "$PYTHON_DIR"

# بناء React Frontend إذا لم يُبنى
if [ ! -d "$FRONTEND/build" ]; then
    echo "🌐 بناء Frontend React..."
    cd "$FRONTEND"
    npm install
    npm run build
fi

echo "🌐 نسخ ملفات Frontend React..."
cp -r "$FRONTEND/build/"* "$ASSETS_DIR/"

echo "🧠 نسخ Backend Python..."
cp -r "$BACKEND/"* "$PYTHON_DIR/"

# إنشاء MainActivity.kt مع WebView
cat > "$JAVA_DIR/MainActivity.kt" << 'EOF'
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
        py.getModule("main") // main.py backend

        webView = findViewById(R.id.webview)
        webView.webViewClient = WebViewClient()
        webView.settings.javaScriptEnabled = true
        webView.loadUrl("file:///android_asset/index.html")
    }
}
EOF

# إنشاء activity_main.xml
cat > "$RES_DIR/activity_main.xml" << 'EOF'
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

# إنشاء AndroidManifest.xml
cat > "$APP_DIR/src/main/AndroidManifest.xml" << 'EOF'
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

# إنشاء build.gradle
cat > "$APP_DIR/build.gradle" << 'EOF'
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

echo "✅ مشروع Android جاهز! ابدأ Android Studio لتوليد APK"
echo "📂 المسار: $ANDROID_PROJECT
echo "🔥 بعد فتح المشروع: Build → Build APK(s) → Build APK(s)"

