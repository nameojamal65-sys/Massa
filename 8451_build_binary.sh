#!/bin/bash
echo "🚀 Building VehicleApp binary..."

# تصحيح PYTHONPATH
export PYTHONPATH=$(pwd):$PYTHONPATH

# تحويل الكود إلى ملف تنفيذي مستقل
pyinstaller --onefile core/vehicle_manager.py --name VehicleApp

echo "✅ Binary built! تجد الملف داخل dist/VehicleApp"
