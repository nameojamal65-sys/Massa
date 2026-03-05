# -----------------------------
# Trimex + AbuMftah Auto Setup
# -----------------------------

import os
import trimex  # تأكد Trimex مثبتة في البيئة

print('--- Step 1: Updating AbuMftah ---')
os.system('abumftah update')

# قائمة الأدوات المطلوبة
required_tools = ['TrimexCAD', 'TrimexRevit', 'SteelLibrary', 'CladdingModule']

for tool in required_tools:
    print(f'Installing {tool}...')
    os.system(f'abumftah install {tool}')

# تحقق من الأدوات المثبتة
os.system('abumftah list-installed')
print('Environment setup complete.\n')

# -----------------------------
# Step 2: Execute First Engine Task
# -----------------------------

project_file = 'SecondarySteelSection.json'  # ضع هذا الملف في workspace

print('--- Loading Project ---')
trimex.load_project(project_file)

print('--- Generating Floor Sections ---')
trimex.generate_sections(floors=26, floor_height=3.4)

print('--- Applying Cladding and Windows ---')
trimex.apply_cladding(panel_size=(0.4,0.6), thickness=0.03)
trimex.apply_windows(project_file)

print('--- Hiding Secondary Steel Layers ---')
trimex.hide_layer('SecondarySteel')

print('--- Exporting Outputs ---')
trimex.export('PDF', 'Tower_26F_Sections.pdf')
trimex.export('DWG', 'Tower_26F_Sections.dwg')

print('First engine task executed successfully!')
