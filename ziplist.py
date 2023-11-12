# !/usr/bin/env python3

# https://www.voidtools.com/forum/viewtopic.php?t=1594
# https://github.com/Bluscream/script/blob/master/ziplist.py

# region INSTALL

# python3 -m pip install py7zr
# python3 ziplist.py

# endregion INSTALL

# region imports
import os
import subprocess
from datetime import datetime
import zipfile
import py7zr
import csv
import logging
from decimal import Decimal, getcontext
getcontext().prec = 50
# endregion imports

# region SETTINGS

# edit your "Compressed" filter in Everything to change which archives are included
use_everything_1_5_alpha = True
ziplist_file = 'ziplist.efu'
zipcontents_file = 'zipcontents.efu'
path_separator = '\\'
min_archive_size_bytes = 22
log_file = 'ziplist.log'

# endregion SETTINGS


# region logging
formatter = logging.Formatter('%(asctime)s - %(levelname)s - %(message)s')
logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger()
# Create a file handler and set the log file path
if log_file:
    file_handler = logging.FileHandler(log_file)
    file_handler.setLevel(logging.DEBUG)
    file_handler.setFormatter(formatter)
    logger.addHandler(file_handler)
# Create a console handler
console_handler = logging.StreamHandler()
console_handler.setLevel(logging.DEBUG)
console_handler.setFormatter(formatter)
# logger.addHandler(console_handler)
# endregion logging

def es(cmd: list[str]):
    cmd = ['es'] + cmd + (['-instance', '1.5a'] if use_everything_1_5_alpha else [])
    logger.debug(f'Running command: {" ".join(cmd)}')
    subprocess.run(cmd)

# Step 1: Use the 'everything' CLI to find all archives and save the list to 'ziplist.txt'
logger.debug('Running "everything" CLI to find all archives...')
es(['zip:', '-export-efu', ziplist_file])

# Step 2: Read the list of archives from 'ziplist.txt'
logger.debug(f'Reading the list of archives from {ziplist_file}...')
archives = []
with open(ziplist_file, newline='') as csvfile:
    has_header = csv.Sniffer().has_header(csvfile.read(1024))
    csvfile.seek(0)
    reader = csv.reader(csvfile, delimiter=',', quotechar='"')
    if has_header: next(reader)
    for row in reader:
        archives.append(row[0])

def filetime_from_datetime(dt: datetime):
    return Decimal((dt - datetime(1601, 1, 1)).total_seconds() * 1_000_000) * Decimal(10)
def replace_pathsep(text): return text.replace("/",path_separator).replace("\\",path_separator)

# Step 3: Get the list of files in all archives and save them to 'ziplist.EFU'
logger.debug('Getting the list of files in all archives...')
with open(zipcontents_file, 'w', newline='') as file:
    writer = csv.writer(file)
    writer.writerow(['Filename', 'Size', 'Date Modified', 'Date Created', 'Attributes'])

    for archive in archives:
        if not os.path.isfile(archive):
            logger.error(f'{archive} not found!')
            continue
        # if file is smaller than 22 bytes, it's probably not a valid archive
        if os.path.getsize(archive) < min_archive_size_bytes:
            logger.warning(f'{archive} is too small, skipping...')
            continue
        try:
            is_7z = py7zr.is_7zfile(archive)
            is_zip = zipfile.is_zipfile(archive)
            if not is_7z and not is_zip:
                logger.error(f'{archive} not supported!')
                continue
            with py7zr.SevenZipFile(archive, mode='r') if is_7z else zipfile.ZipFile(archive, 'r') as z:
                for filename in z.getnames() if is_7z else z.namelist():
                    if filename.endswith('/') or filename.endswith('\\'): continue
                    info = z.getinfo(filename)
                    archive = replace_pathsep(archive.replace("\"",""))
                    virtualpath = f'{archive}\\{replace_pathsep(filename)}'.replace("\"","")
                    size = info.file_size
                    modified = info.modified if py7zr.is_7zfile(archive) else datetime(*info.date_time)
                    created = info.created if py7zr.is_7zfile(archive) else modified
                    # logger.debug(f'Processing file: {filename} (modified: {modified}, created: {created})')
                    modified = filetime_from_datetime(modified)
                    created = filetime_from_datetime(created)
                    # logger.debug(f'Processing file: {filename} (modified: {modified}, created: {created})')
                    attributes = info.external_attr
                    writer.writerow([virtualpath, size, modified, created, attributes])
                    # logger.debug(f'Processed file: {filename}')
            logger.info(f'Processed {archive}...')
        except Exception as e:
            logger.error(f'{archive}: {e}')

logger.debug('Script execution completed.')
