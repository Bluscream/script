import subprocess
import os
from datetime import datetime
import zipfile
import py7zr
import csv
import logging
from decimal import Decimal, getcontext
getcontext().prec = 50

ziplist_file = 'ziplist.efu'
zipcontents_file = 'zipcontents.efu'

# region logging
logging.basicConfig(level=logging.DEBUG, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger()
# Create a file handler and set the log file path
log_file = 'debug.log'
file_handler = logging.FileHandler(log_file)
file_handler.setLevel(logging.DEBUG)
# Create a console handler
console_handler = logging.StreamHandler()
console_handler.setLevel(logging.DEBUG)
# Create a formatter and add it to the handlers
formatter = logging.Formatter('%(asctime)s - %(levelname)s - %(message)s')
file_handler.setFormatter(formatter)
console_handler.setFormatter(formatter)
# Add the handlers to the logger
logger.addHandler(file_handler)
# logger.addHandler(console_handler)
# endregion logging

def es(cmd: list[str]):
    cmd = ['es'] + cmd + ['-instance', '1.5a']
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

# Step 3: Get the list of files in all archives and save them to 'ziplist.EFU'
logger.debug('Getting the list of files in all archives...')
with open('zipcontents.EFU', 'w', newline='') as file:
    writer = csv.writer(file)
    writer.writerow(['Filename', 'Size', 'Date Modified', 'Date Created', 'Attributes'])

    for archive in archives:
        if not os.path.exists(archive):
            logger.warning(f'Archive not found: {archive}')
            continue
        logger.debug(f'Processing archive: {archive}')
        try:
            with py7zr.SevenZipFile(archive, mode='r') if py7zr.is_7zfile(archive) else zipfile.ZipFile(archive, 'r') as z:
                for filename in z.getnames() if py7zr.is_7zfile(archive) else z.namelist():
                    info = z.getinfo(filename)
                    archive = archive.replace("\"","")
                    filename = filename.replace("/","\\")
                    virtualpath = f'{archive}\\{filename}'.replace("\"","")
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
        except Exception as e:
            logger.error(f'Error processing archive: {archive}')
            logger.error(e)

logger.debug('Script execution completed.')
