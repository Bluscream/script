import json
import os
import argparse
import logging

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s [%(levelname)s] %(message)s')

# Initialize invalid_count globally
invalid_count =  0

def clean_dict(data):
    global invalid_count  # Declare invalid_count as global inside the function
    if isinstance(data, dict):
        cleaned_data = {}
        for key, value in data.items():
            cleaned_value = clean_dict(value)
            if cleaned_value:
                cleaned_data[key] = cleaned_value
            else:
                invalid_count +=  1
                logging.info(f"Removed invalid key-value pair: {key} -> {value}")
        return cleaned_data if cleaned_data else None
    elif isinstance(data, list):
        cleaned_data = []
        for item in data:
            cleaned_item = clean_dict(item)
            if cleaned_item is not None:
                cleaned_data.append(cleaned_item)
        return cleaned_data if cleaned_data else None
    else:
        # Check for empty strings, "null", "none", {}, []
        if data in ({}, [], "", "null", "none", "Null", "None", "NULL", "NONE"):
            return None
        return data

def main():
    parser = argparse.ArgumentParser(description='Remove null values from JSON files.')
    parser.add_argument('input_file', help='Path to the input JSON file.')
    args = parser.parse_args()

    # Load JSON file into a dictionary
    with open(args.input_file, 'r') as f:
        data = json.load(f)

    # Clean the dictionary
    cleaned_data = clean_dict(data)

    # Save the cleaned dictionary to a new JSON file
    output_filename = os.path.splitext(args.input_file)[0] + '_out.json'
    with open(output_filename, 'w') as f:
        json.dump(cleaned_data, f, indent=4)

    logging.info(f'Cleaned JSON saved to {output_filename}. Number of invalid key-value pairs removed: {invalid_count}')

if __name__ == '__main__':
    main()