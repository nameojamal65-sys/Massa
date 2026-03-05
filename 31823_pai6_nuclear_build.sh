#!/data/data/com.termux/files/usr/bin/bash
set -e

clear
echo "👑 PAI6 — NUCLEAR AUTONOMOUS APK BUILDER"
echo "======================================"
sleep 1

BASE=~/pai6_final_build
ASSETS=~/pai6_assets

mkdir -p "$ASSETS"

echo "⚙️ Installing core dependencies..."
pkg update -y && pkg upgrade -y
pkg install -y python git clang make cmake unzip zip openjdk-17 wget

pip install --upgrade pip
pip install buildozer cython virtualenv

echo "📦 Downloading NUCLEAR assets..."

cd "$ASSETS"

wget -O intro.mp4 https://filesamples.com/samples/video/mp4/sample_640x360.mp4
wget -O logo.png https://upload.wikimedia.org/wikipedia/commons/thumb/2/2f/Google_2015_logo.svg/512px-Google_2015_logo.svg.png

cat <<'PYEOF' > license_manager.py
import qrcode,uuid,datetime,os

def generate_license():
    key=str(uuid.uuid4())
    data={
        "license":key,
        "date":str(datetime.datetime.utcnow())
    }
    qr=qrcode.make(str(data))
    qr.save("pai6_license.png")
    return key

if __name__=="__main__":
    k=generate_license()
    print("PAI6 LICENSE GENERATED:",k)
PYEOF

echo "✅ Assets downloaded and prepared"

cd "$BASE"

echo "⚙️ Starting FULL NUCLEAR BUILD..."

chmod +x build_auto.sh
./build_auto.sh

echo
echo "======================================"
echo "🎯 PAI6 — NUCLEAR APK BUILD FINISHED"
echo "======================================"
echo

APK=$(ls $BASE/bin/*.apk 2>/dev/null | head -n 1)

if [ -z "$APK" ]; then
    echo "❌ APK NOT GENERATED — CHECK LOGS"
else
    echo "✅ APK GENERATED SUCCESSFULLY:"
    echo "$APK"
    echo "📏 APK SIZE:"
    du -h "$APK"
fi

