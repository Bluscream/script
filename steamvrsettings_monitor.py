import time
import json
import logging
from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler

# Configure logging
logging.basicConfig(level=logging.DEBUG,
                    format='%(asctime)s - %(levelname)s - %(message)s',
                    datefmt='%Y-%m-%d %H:%M:%S')

class FileChangeHandler(FileSystemEventHandler):
    def __init__(self, file_template, file_to_monitor):
        self.file_template = file_template
        self.file_to_monitor = file_to_monitor
        logging.info("Initialized FileChangeHandler")

    def on_modified(self, event):
        logging.info(f"Modified: {event.src_path}")
        if event.src_path == self.file_to_monitor:
            try:
                with open(self.file_template, 'r') as x_file:
                    x_data = json.load(x_file)
                with open(self.file_to_monitor, 'r') as y_file:
                    y_data = json.load(y_file)
                
                # Merge y_data with x_data, keeping new keys from y_data
                merged_data = x_data.copy()
                merged_data.update(y_data)
                
                # Track changes
                changes = []
                for key, new_value in x_data.items():
                    if key in y_data and y_data[key] != new_value:
                        changes.append(f"- {key} = {y_data[key]}")
                
                with open(self.file_to_monitor, 'w') as y_file:
                    json.dump(merged_data, y_file, indent=4)
                
                if changes:
                    logging.info(f"File {self.file_to_monitor} has been modified and merged with {self.file_template} content. Changes:")
                    for change in changes:
                        logging.info(change)
                else:
                    logging.info(f"File {self.file_to_monitor} has been modified and merged with {self.file_template} content. No changes detected.")
            except Exception as e:
                logging.error(f"Error processing file: {e}")

def monitor_file(x_path, y_path):
    event_handler = FileChangeHandler(x_path, y_path)
    observer = Observer()
    observer.schedule(event_handler, path=y_path, recursive=False)
    observer.start()
    try:
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        observer.stop()
    observer.join()

if __name__ == "__main__":
    file_template = r'C:\Program Files (x86)\Steam\config\steamvr.vrsettings.template'
    file_to_monitor = r'C:\Program Files (x86)\Steam\config\steamvr.vrsettings'
    logging.info(f"file_template={file_template}")
    logging.info(f"file_to_monitor={file_to_monitor}")
    monitor_file(file_template, file_to_monitor)
