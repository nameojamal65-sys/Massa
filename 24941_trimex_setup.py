#!/usr/bin/env python3
# trimex_setup.py
# سكريبت إعداد Trimex + تنفيذ المهمة الأولى

import os
import trimex

# ------------------------
# Step 1: إعداد البيئة عبر AbuMftah
# ------------------------
print('--- Step 1: Environment Setup via AbuMftah ---')
os.system('abumftah update')

required_tools = ['TrimexCAD', 'TrimexRevit', 'SteelLibrary', 'CladdingModule']
for tool in required_tools:
    print(f'Installing {tool}...')
    os.system(f'abumftah install {tool}')

os.system('abumftah list-installed')
print('Environment setup complete.\n')

# ------------------------
# Step 2: تنفيذ المهمة الأولى في Trimex
# ------------------------
print('--- Step 2: Executing First Engine Task ---')

# تأكد أن ملف المشروع موجود في workspace
project_file = 'SecondarySteelSection.json'

# تحميل إعدادات المشروع
trimex.load_project(project_file)

# إنشاء أقسام الطوابق
trimex.generate_sections(floors=26, floor_height=3.4)

# تطبيق الكسوة والزجاج
trimex.apply_cladding(panel_size=(0.4, 0.6), thickness=0.03)
trimex.apply_windows(project_file)

# إخفاء طبقات الحديد الثانوية
trimex.hide_layer('SecondarySteel')

# تصدير الملفات النهائية
trimex.export('PDF', 'Tower_26F_Sections.pdf')
trimex.export('DWG', 'Tower_26F_Sections.dwg')

print('First engine task executed successfully.')

