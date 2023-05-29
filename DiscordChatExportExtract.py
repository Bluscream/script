import csv
import shutil
import os
from pathlib import Path

# Define input and output paths
input_path = r'C:\Users\blusc\AppData\Local\Temp\yumi\YUMInity - ━ Community ━ - 📸-bilder [545757007869902858].csv'
output_dir = r'C:\Users\blusc\AppData\Local\Temp\yumi'
author_id = '295157845706670080'

# Create output directory if it doesn't exist
if not os.path.exists(output_dir):
    os.makedirs(output_dir)

# Loop through the CSV file
with open(input_path, 'r', encoding='utf-8-sig') as csvfile:
    reader = csv.reader(csvfile)
    header = next(reader)  # Skip the header row
    author_id_idx = header.index('AuthorID')
    attachments_idx = header.index('Attachments')
    for row in reader:
        # Check if the current row corresponds to the target author
        if row[author_id_idx] == author_id:
            # Check if the 'Attachments' field contains a file path
            if row[attachments_idx]:
                for file_path in row[attachments_idx].split(","):
                    # Extract the file name from the file path
                    # file_name = os.path.basename(file_path)
                    # Construct the full path to the file
                    input_file_path = Path(output_dir, file_path)
                    output_file_path = input_file_path.parent.parent / input_file_path.name
                    # Move the file to the output directory
                    print(f"Moving {input_file_path} to {output_file_path}")
                    shutil.move(input_file_path, output_file_path)
