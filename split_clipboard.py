import pyperclip
import keyboard
import threading
import textwrap
from time import sleep
from hashlib import md5 as _md5

def calculate_md5(string):
    return _md5(string.encode('utf-8')).hexdigest()

# Read the clipboard content
clipboard_content = pyperclip.paste()
print(f"Received clipboard with length {len(clipboard_content)}: {calculate_md5(clipboard_content)}")

# Split the content into chunks of 499 characters
chunk_size = 1999

# chunks = [clipboard_content[i:i + chunk_size] for i in range(0, len(clipboard_content), chunk_size)]
chunks = textwrap.wrap(clipboard_content, chunk_size, break_long_words=False, break_on_hyphens=False)

# Counter to keep track of the current chunk index
chunk_index = 0

# Flag to indicate whether the next chunk should be set on clipboard
set_next_chunk = False

def on_hotkey():
    global set_next_chunk
    set_next_chunk = True
    # if event.name == 'v' and event.event_type == 'down' and any(mod in event.modifiers for mod in ['ctrl', 'strg']):
    #     set_next_chunk = True
    # elif event.name == 'einfg' and event.event_type == 'down' and any(mod in event.modifiers for mod in ['shift', 'umschalt']):
    #     set_next_chunk = True

keyboard.add_hotkey('ctrl+v', on_hotkey, args=(None))
# keyboard.add_hotkey('strg+v', on_hotkey, args=(None))
keyboard.add_hotkey('shift+ins', on_hotkey, args=(None))
# keyboard.add_hotkey('umschalt+einfg', on_hotkey, args=(None))

# Register the hotkey event handler
# keyboard.on_press(on_hotkey)

# Function to set the next chunk on clipboard
def set_next_clipboard_chunk():
    global chunk_index
    global set_next_chunk
    while True:
        if set_next_chunk and chunk_index < len(chunks):
            # Get the next chunk
            chunk = chunks[chunk_index]

            # Set the chunk on clipboard
            pyperclip.copy(chunk)

            print(f"Ready to paste chunk {chunk_index + 1}/{len(chunks)}: {calculate_md5(chunk)}")
            
            # Update the chunk index and reset the flag
            chunk_index += 1
            set_next_chunk = False

        sleep(0.1)

set_next_clipboard_chunk()

input()

# Start a separate thread to set the chunks on clipboard
# thread = threading.Thread(target=set_next_clipboard_chunk)
# thread.daemon = True
# thread.start()

# Start the event listener loop
# keyboard.wait()
