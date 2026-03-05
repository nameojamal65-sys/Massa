BASE=~/sovereign_system_full

echo '📦 إنشاء النظام الكامل في:' $BASE
mkdir -p $BASE/sovereign_system/data/processed
mkdir -p $BASE/sovereign_system/reports

# ملفات Python
cat << 'PY1' > $BASE/sovereign_system/core_launcher.py
print('🟢 Sovereign Core Active')
PY1

cat << 'PY2' > $BASE/sovereign_system/data_collector.py
import json
print('📥 Collecting data...')
data = {"sensor1":100, "sensor2":200}
with open('sovereign_system/data/raw_data.json','w') as f: json.dump(data,f)
print('✅ Data collected')
PY2

cat << 'PY3' > $BASE/sovereign_system/data_processor.py
import json, os
print('⚙️ Processing...')
with open('sovereign_system/data/raw_data.json') as f: data=json.load(f)
processed={k:v*10 for k,v in data.items()}
os.makedirs('sovereign_system/data/processed',exist_ok=True)
with open('sovereign_system/data/processed/processed.json','w') as f: json.dump(processed,f)
print('✅ Processed')
PY3

cat << 'PY4' > $BASE/sovereign_system/analytics_engine.py
import json
print('📊 Analytics...')
with open('sovereign_system/data/processed/processed.json') as f: d=json.load(f)
print('Total:',sum(d.values()))
PY4

cat << 'PY5' > $BASE/sovereign_system/report_generator.py
import json,os
print('📝 Report...')
with open('sovereign_system/data/processed/processed.json') as f: d=json.load(f)
report=f"Processed Data:\n{json.dumps(d,indent=2)}\n"
os.makedirs('sovereign_system/reports',exist_ok=True)
with open('sovereign_system/reports/report.txt','w') as r: r.write(report)
print('✅ Report created')
PY5

cat << 'PY6' > $BASE/sovereign_system/dashboard.py
from flask import Flask
app=Flask(__name__)
@app.route('/')
def home(): return '🟢 Sovereign Data Platform Online!'
if __name__=='__main__': app.run(host='0.0.0.0',port=8080)
PY6

cat << 'SH' > $BASE/sovereign_system/run_full_system.sh
echo '🚀 System Started'
python3 core_launcher.py
python3 data_collector.py
python3 data_processor.py
python3 analytics_engine.py
python3 report_generator.py
python3 dashboard.py
SH

chmod +x $BASE/sovereign_system/*.py
chmod +x $BASE/sovereign_system/run_full_system.sh

cd ~
zip -r sovereign_system_full.zip sovereign_system_full
echo '✅ ZIP Created: ~/sovereign_system_full.zip'
