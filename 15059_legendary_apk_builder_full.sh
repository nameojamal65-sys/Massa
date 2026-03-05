#!/data/data/com.termux/files/usr/bin/bash
# 🚀 Legendary Full APK Builder for Termux

# 1️⃣ إعداد المسارات
BASE="$HOME/Legendary_Dashboard/v6"
FRONTEND="$BASE/frontend"
ANDROID_PROJECT="$HOME/Legendary_v6_APK"
BACKEND="$BASE/backend"

echo "📦 بدء إعداد مشروع Android جديد..."

# 2️⃣ بناء React frontend
cd "$FRONTEND" || { echo "❌ لا يوجد مجلد frontend!"; exit 1; }

echo "🌐 تثبيت الحزم اللازمة لـ React..."
npm install || { echo "❌ فشل npm install"; exit 1; }

echo "🌐 بناء مشروع React frontend..."
npm run build || { echo "❌ فشل بناء React frontend"; exit 1; }

# 3️⃣ إنشاء مجلد Android project
mkdir -p "$ANDROID_PROJECT"
cd "$ANDROID_PROJECT" || { echo "❌ فشل الانتقال لمجلد Android project"; exit 1; }

mkdir -p app/src/main/{java/com/legendaryv6,assets,python,res/layout}

# 4️⃣ نسخ frontend build
if [ -d "$FRONTEND/build" ]; then
    echo "🌐 نسخ ملفات frontend build..."
    cp -r "$FRONTEND/build/"* app/src/main/assets/
else
    echo "⚠️ مجلد frontend build غير موجود!"
fi

# 5️⃣ نسخ backend Python
echo "🧠 نسخ ملفات Backend Python..."
cp -r "$BACKEND/"* app/src/main/python/

# 6️⃣ إنشاء MainActivity.kt
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
        py.getModule("main") // main.py backend

        webView = findViewById(R.id.webview)
        webView.webViewClient = WebViewClient()
        webView.settings.javaScriptEnabled = true
        webView.loadUrl("file:///android_asset/index.html")
    }
}
EOF

# 7️⃣ إنشاء layout XML
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

# 8️⃣ إنشاء AndroidManifest.xml
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

# 9️⃣ إنشاء build.gradle (Module: app)
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

# 10️⃣ صلاحيات التنفيذ للسكربت
chmod +x "$ANDROID_PROJECT"

echo "✅ مشروع Android جاهز!"
echo "📂 المسار: $ANDROID_PROJECT"
echo "🔥 بعد فتح المشروع: Build → Build APK(s) → Build APK(s) في Android Studio"
