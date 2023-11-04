import ctypes
ctypes.windll.user32.ShowWindow( ctypes.windll.kernel32.GetConsoleWindow(), 6 )
import keyboard
import time
import pyperclip

max_chars = 500

def paste_text():
    global max_chars
    # Check if the active window is fullscreen
    if ctypes.windll.user32.SystemParametersInfoW(0x2000, 0, None, 0):
        print("Is fullscreen!")
    clipboard_content = pyperclip.paste()
    if len(clipboard_content) > max_chars:
        print(f"Clipboard content is over {max_chars}, use CTRL+ALT+V instead")
        return
    for char in clipboard_content:
        if keyboard.is_pressed('Esc'): break
        keyboard.write(char)
        time.sleep(0.05)  # Adjust this value if needed

# keyboard.add_hotkey('Ctrl+b', paste_text)
# keyboard.wait('Ctrl+Shift+b')  # This will keep the script running until Ctrl+Shift+b is pressed

paste_text()