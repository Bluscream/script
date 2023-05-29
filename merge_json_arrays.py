import argparse
import json

def process_array(array):
    processed_array = []
    for item in array:
        if ":" not in item:
            # Add default port to items without a port
            processed_array.append(f"{item}:28960")
        else:
            processed_array.append(item)
    return processed_array

def merge_json_files(input_files:list[str], output_file:str):
    merged_array = []

    # Iterate over each input file
    for file_path in input_files:
        # Read the JSON file
        with open(file_path, 'r') as file:
            data = json.load(file)
            print(f"Got array with {len(data)} elements from {file_path}")
        data = process_array(data)
        # Merge the arrays without duplicates
        merged_array = list(set(merged_array + data))
        print(f"Merged array is now {len(merged_array)} elements large.")
    merged_array = sorted(merged_array)
    # Write the merged array into the output file
    with open(output_file, 'w') as file:
        print(f"Writing {len(merged_array)} elements to {output_file}")
        json.dump(merged_array, file, indent=4)

# Create the argument parser
parser = argparse.ArgumentParser(description='Merge multiple JSON files.')

# Add the positional arguments
# parser.add_argument('input_files', nargs='+', help='input JSON files')
parser.add_argument('--output_file', default='output.json', help='output JSON file')

# Parse the command-line arguments
args = parser.parse_args()

if not "input_files" in args or not args.input_files:
    args.input_files = [
        "G:/Steam/steamapps/common/Call of Duty Modern Warfare 2/players/favourites.json",
        "D:/Downloads/favourites.json",
        "D:/Downloads/favorites.json",
    ]

# Merge the JSON files
merge_json_files(args.input_files, args.output_file)