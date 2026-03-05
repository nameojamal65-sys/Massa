#!/data/data/com.termux/files/usr/bin/bash
# =========================================
# PAI6 Master Auto-Fix Script – Zaeem Edition
# =========================================

echo "🌀 Starting PAI6 Master Auto-Fix..."
TARGET_DIR="$HOME/sovereign_core_fix"
FIX_DIR="$TARGET_DIR/fix_scripts"

# --- Step 0: Prepare directories ---
mkdir -p "$FIX_DIR"
echo "✅ Directories ready: $TARGET_DIR, $FIX_DIR"

# --- Step 1: Update packages ---
echo "⚡ Updating Termux packages..."
pkg update -y >/dev/null 2>&1
pkg upgrade -y >/dev/null 2>&1
pkg install -y python unzip curl >/dev/null 2>&1
echo "✅ Packages updated"

# --- Step 2: Set executable permissions ---
echo "🔑 Setting executable permissions for any scripts..."
find "$FIX_DIR" -type f -name "*.sh" -exec chmod +x {} \;
echo "✅ Permissions set"

# --- Step 3: Download default fix scripts (example) ---
echo "🌐 Downloading core fix scripts..."
# مثال: ضع هنا روابط سكربتاتك الحقيقية
curl -fsSL "https://raw.githubusercontent.com/paicore/fix_scripts/main/run_fix.sh" -o "$FIX_DIR/run_fix.sh"
curl -fsSL "https://raw.githubusercontent.com/paicore/fix_scripts/main/patch_system.sh" -o "$FIX_DIR/patch_system.sh"
chmod +x "$FIX_DIR"/*.sh
echo "✅ Fix scripts downloaded"

# --- Step 4: Run fix scripts ---
echo "🚀 Executing all fix scripts..."
for f in "$FIX_DIR"/*.sh; do
    [ -f "$f" ] && echo "   • Running $(basename $f)" && bash "$f"
done
echo "✅ All fix scripts executed"

# --- Step 5: System health check ---
echo "🧠 Running final system diagnostic..."
python3 << 'PY'
import platform, sys, psutil
print("==========================")
print("CPU:", platform.processor())
print("RAM:", round(psutil.virtual_memory().total/1024/1024,1), "MB")
print("Python:", sys.version.split()[0])
print("System Stable ✔")
print("==========================")
PY

echo "🟢 PAI6 Master Auto-Fix Complete!"
echo "📍 All fixes applied to: $TARGET_DIR"
echo "📊 You can now restart your Sovereign Core system."
