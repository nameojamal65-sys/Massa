#!/data/data/com.termux/files/usr/bin/bash

echo "🚀 Starting Sovereign Ultra Pro APK Build..."

# --- إعدادات ---
EXPO_PROJECT_DIR="$HOME/sovereign_android_ultra_pro"
REACT_FRONTEND_DIR="$HOME/sovereign_dashboard"
BACKEND_FILE="$HOME/sovereign_core_full.py"
LOCAL_API_PORT=5000
APP_ICON="$HOME/sovereign_icon.png"

# --- تثبيت Node و Expo CLI ---
pkg install nodejs npm -y
npm install -g expo-cli

# --- إنشاء مشروع Expo React Native جديد ---
if [ ! -d "$EXPO_PROJECT_DIR" ]; then
    echo "📁 Creating Expo Project..."
    expo init sovereign_android_ultra_pro --template blank
else
    echo "📁 Expo project exists, skipping creation."
fi

cd $EXPO_PROJECT_DIR || exit

# --- نسخ واجهة React كاملة + Dashboard + Chat + External AI ---
if [ -d "$REACT_FRONTEND_DIR/src" ]; then
    echo "📄 Copying full React frontend..."
    mkdir -p src
    cp -r $REACT_FRONTEND_DIR/src/* src/
else
    echo "⚠️ React frontend not found."
fi

# --- نسخ Backend Python داخل assets ---
if [ -f "$BACKEND_FILE" ]; then
    echo "📦 Copying Python backend..."
    mkdir -p assets/backend
    cp $BACKEND_FILE assets/backend/
else
    echo "⚠️ Backend file not found."
fi

# --- إعداد env API ---
echo "⚙️ Setting API URL for local backend..."
echo "VITE_API_URL=http://localhost:$LOCAL_API_PORT" > .env

# --- إضافة أيقونة التطبيق ---
if [ -f "$APP_ICON" ]; then
    mkdir -p assets
    cp $APP_ICON assets/icon.png
fi

# --- إنشاء SplashScreen + Dashboard Ultimate Pro ---
APP_JS="$EXPO_PROJECT_DIR/App.js"
cat << 'EOF' > $APP_JS
import React, { useEffect, useState } from 'react';
import { View, Text, Button, ScrollView, TextInput, ActivityIndicator, StyleSheet } from 'react-native';
import axios from 'axios';

export default function App() {
  const [loading, setLoading] = useState(true);
  const [systemData, setSystemData] = useState({});
  const [result, setResult] = useState('');
  const [chatInput, setChatInput] = useState('');
  const [chatHistory, setChatHistory] = useState([]);
  const API_URL = 'http://localhost:5000';

  useEffect(() => {
    setTimeout(() => setLoading(false), 2000); // SplashScreen
    loadData();
    const interval = setInterval(loadData, 5000); // تحديث مباشر
    return () => clearInterval(interval);
  }, []);

  const loadData = () => {
    axios.get(API_URL + "/data")
      .then(res => setSystemData(res.data))
      .catch(err => console.log(err));
  };

  const runTask = (endpoint, payload={}) => {
    axios.post(API_URL + endpoint, payload)
      .then(res => { setResult(JSON.stringify(res.data, null, 2)); loadData(); })
      .catch(err => setResult(err.toString()));
  };

  const sendChat = () => {
    axios.post(API_URL + "/task/external_ai_chat", {query: chatInput, mode:"execute"})
      .then(res => {
        setChatHistory([...chatHistory, {question: chatInput, answer: res.data.response}]);
        setChatInput('');
      }).catch(err => console.log(err));
  };

  if (loading) return (<View style={styles.container}><Text style={styles.title}>🚀 Sovereign Loading...</Text><ActivityIndicator size="large" color="#007aff"/></View>);

  return (
    <ScrollView style={{padding:20}}>
      <Text style={styles.title}>🚀 Sovereign Ultra Pro Dashboard</Text>

      <Text style={styles.subtitle}>⚙️ System Actions</Text>
      <Button title="Heavy Math" onPress={()=>runTask("/task/heavy_math",{n:1000})}/>
      <Button title="AI Formula" onPress={()=>runTask("/task/ai_formula",{x:2})}/>
      <Button title="Fetch Web" onPress={()=>runTask("/task/fetch_web",{url:"https://example.com"})}/>
      <Button title="Refresh Data" onPress={loadData}/>

      <Text style={styles.subtitle}>🧠 External AI Chat (Live Updates)</Text>
      <TextInput value={chatInput} onChangeText={setChatInput} placeholder="Give command..." style={styles.input}/>
      <Button title="Send" onPress={sendChat}/>
      {chatHistory.map((c,i)=>(<View key={i} style={{marginVertical:8}}><Text style={{fontWeight:'bold'}}>You:</Text> {c.question}<Text style={{fontWeight:'bold'}}>AI:</Text> {c.answer}</View>))}

      <Text style={styles.subtitle}>📊 System Data (Live)</Text>
      <Text>{JSON.stringify(systemData,null,2)}</Text>

      <Text style={styles.subtitle}>📦 Last Task Result</Text>
      <Text>{result}</Text>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container:{flex:1, justifyContent:'center', alignItems:'center'},
  title:{fontSize:24, fontWeight:'bold', marginBottom:10},
  subtitle:{fontSize:18, fontWeight:'bold', marginTop:20},
  input:{borderWidth:1, padding:8, marginVertical:10, borderRadius:5}
});
EOF

# --- إنشاء سكربت Build Ultimate Pro APK ---
cat << 'EOF' > build_ultra_pro_apk.sh
#!/bin/bash
echo "🚀 Installing dependencies..."
npm install
expo install

echo "🚀 Starting local Python backend..."
cd assets/backend
nohup python3 sovereign_core_full.py > ../../backend.log 2>&1 &

cd ../../
echo "🚀 Building Ultra Pro APK via Expo..."
expo build:android -t apk
EOF

chmod +x build_ultra_pro_apk.sh

echo "✅ Sovereign Ultra Pro APK Setup Complete!"
echo "Run './build_ultra_pro_apk.sh' inside $EXPO_PROJECT_DIR to start backend and build APK."

