from json import dump, load
from pathlib import Path

app = 'Shadow.exe'
file = Path("C:/Users/Bluscream/Desktop/20250130_adguard_filtering_log_records.json")
data = None
with open(file, "rb") as f: data = load(f)
records = []
for record in data['LogRecords']:
    if record['AppPath'] == app:
        records.append(record)
print(f"Found {len(records)} / {len(data['LogRecords'])} records matching {app} in \"{file}\"")
input("Replace?")
data['LogRecords'] = records
with open(file.with_suffix(".filtered.json"), "w") as f: dump(data, f, indent=4)
print("hi")
