import os
import csv

# Path to the directory containing the subdirectories
directory_path = r'G:\Steam\steamapps\workshop\content\546560'

# Path to the output CSV file
output_file = 'mods.csv'

# List to store the directory names and titles
mods_list = []

# Iterate over each subdirectory
for subdir in os.listdir(directory_path):
    subdir_path = os.path.join(directory_path, subdir)
    
    # Check if the subdirectory contains the publish_data.txt file
    publish_data_path = os.path.join(subdir_path, 'publish_data.txt')
    if os.path.isfile(publish_data_path):
        # Read the title from the publish_data.txt file
        with open(publish_data_path, 'r') as file:
            lines = file.readlines()
            for line in lines:
                if 'title' in line:
                    title = line.split('"')[3]
                    mods_list.append([subdir, title])
                    print(f"Found mod {subdir}: \"{title}\"")
                    break

# Write the directory names and titles to the CSV file
with open(output_file, 'w', newline='') as file:
    writer = csv.writer(file, delimiter=';')
    writer.writerow(['Directory Name', 'Title'])
    writer.writerows(mods_list)

print(f"CSV file '{output_file}' has been created.")
