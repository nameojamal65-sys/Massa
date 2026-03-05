#!/data/data/com.termux/files/usr/bin/bash
# 🚀 Legendary v6 Full Auto APK Builder

# --- إعداد المسارات ---
BASE="$HOME/Legendary_Dashboard/v6"
FRONTEND="$BASE/frontend/build"
BACKEND="$BASE/backend"
ANDROID_PROJECT="$HOME/Legendary_v6_APK"

echo "📦 بدء إعداد مشروع Android جديد..."

# --- إنشاء مجلد المشروع إذا لم يكن موجود ---
mkdir -p "$ANDROID_PROJECT"
cd "$ANDROID_PROJECT"

# --- إنشاء مجلدات المشروع الأساسية ---
mkdir -p app/src/main/{java/com/legendaryv6,assets,python,res/layout}

# --- نسخ Frontend build ---
if [ -d "$FRONTEND" ]; then
    echo "🌐 نسخ ملفات frontend build..."
    cp -r "$FRONTEND"/* app/src/main/assets/
else
    echo "⚠️ مجلد Frontend build غير موجود! تأكد من بناء React frontend أولاً."
fi

# --- نسخ Backend Python ---
echo "🧠 نسخ ملفات Backend Python..."
cp -r "$BACKEND"/* app/src/main/python/

# --- إنشاء MainActivity.kt مع WebView ---
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
        Python.getInstance().getModule("main") // main.py backend

        webView = findViewById(R.id.webview)
        webView.webViewClient = WebViewClient()
        webView.settings.javaScriptEnabled = true
        webView.loadUrl("file:///android_asset/index.html")
    }
}
EOF

# --- إنشاء layout XML ---
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

# --- إنشاء AndroidManifest.xml ---
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

# --- إنشاء build.gradle ---
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

# --- تهيئة Buildozer (اختياري) ---
if [ ! -f buildozer.spec ]; then
    echo "⚙️ تهيئة Buildozer..."
    buildozer init
fi

# --- بناء APK Debug تلقائي ---
echo "🔨 بدء بناء APK..."
buildozer -v android debug

# --- عرض المسار النهائي لـ APK ---
APK_PATH=$(find bin -name "*.apk" | head -n 1)
if [ -f "$APK_PATH" ]; then
    echo "✅ تم إنشاء APK بنجاح: $APK_PATH"
else
    echo "⚠️ حدث خطأ أثناء إنشاء APK"
fi

echo "🔥 انتهى البناء! يمكنك فتح المشروع في Android Studio أو تثبيت APK مباشرة."
