import os
import filecmp
import subprocess
import concurrent.futures
import sys
from collections import defaultdict
from everything import EverythingSearch, SearchOptions
# from ctypes import windll, shell32

def process_file_list(file_dict: dict):
    with concurrent.futures.ThreadPoolExecutor() as executor:
        for file_list in file_dict.values():
            if len(file_list) > 1:
                original_file = file_list[0]
                future_to_duplicate = {executor.submit(filecmp.cmp, original_file, duplicate_file, shallow=False): duplicate_file for duplicate_file in file_list[1:]}
                for future in concurrent.futures.as_completed(future_to_duplicate):
                    duplicate_file = future_to_duplicate[future]
                    if future.result():
                        # os.remove(duplicate_file)
                        # os.symlink(original_file, duplicate_file)
                        print(f"Replaced {duplicate_file} with a symlink to {original_file}.")

def find_duplicates(path):
    file_dict = {}
    for root, dirs, files in os.walk(path):
        for file in files:
            file_path = os.path.join(root, file)
            file_size = os.path.getsize(file_path)
            if file_size in file_dict:
                file_dict[file_size].append(file_path)
            else:
                file_dict[file_size] = [file_path]
    return file_dict

# Function to find duplicate files and replace them with symlinks
def find_duplicates_es(root_paths, exclusion_paths):
    file_dict = defaultdict(list)
    es = EverythingSearch()

    # Configure the EverythingSearch options
    es.add_option(SearchOptions.SIZE.value)
    es.paths = root_paths
    es.excluded_paths = exclusion_paths
    # Search for files in the root paths
    files = es.search() # , paths=root_paths, excluded_paths=exclusion_paths
    for file in files:
        file_path = os.path.normpath(file['path'])
        file_size = file['size']

        file_dict[(file_size, file_path)].append(file_path)
    input()

# if os.name == 'nt' and not os.environ.get('PYTHONDONTWRITEBYTECODE'):
#     try:
#         script = os.path.abspath(__file__)
#         params = ' '.join([script] + sys.argv[1:])
#         shell32.ShellExecuteW(None, "runas", sys.executable, params, None, 1)
#         sys.exit(0)
#     except Exception as e:
#         print(f"Failed to elevate script: {e}")
#         sys.exit(1)

# Ask for the root paths
root_paths = input("Enter the root paths (separated by ,): ").split(",")

# Ask for the exclusion paths
exclusion_paths = ["C:\Windows","C:\Boot"]
exclusion_paths += input("Enter the exclusion paths (separated by ,): ").split(",")
print("Exclusion Paths: ",';'.join(exclusion_paths))

# Call the function to find and replace duplicates
find_duplicates_es(root_paths, exclusion_paths)