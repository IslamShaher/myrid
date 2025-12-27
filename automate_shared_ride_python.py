#!/usr/bin/env python3
"""
Automated Shared Ride Testing Script for Android Emulators
Uses ADB commands, uiautomator for UI element detection, and parallel execution
"""

import subprocess
import time
import os
import xml.etree.ElementTree as ET
import re
from pathlib import Path
from concurrent.futures import ThreadPoolExecutor
from datetime import datetime

# Configuration
EMULATOR1 = {
    'email': 'emulator1@test.com',
    'password': 'password123',
    'serial': None
}

EMULATOR2 = {
    'email': 'emulator2@test.com',
    'password': 'password123',
    'serial': None
}

COORDS1 = {
    'pickup_lat': '30.0444',
    'pickup_lng': '31.2357',
    'dest_lat': '30.0131',
    'dest_lng': '31.2089'
}

COORDS2 = {
    'pickup_lat': '30.0450',
    'pickup_lng': '31.2360',
    'dest_lat': '30.0140',
    'dest_lng': '31.2095'
}

SCREENSHOT_DIR = Path('emulator_test_screenshots')
SCREENSHOT_DIR.mkdir(exist_ok=True)

STEP_DELAY = 3  # seconds

class EmulatorController:
    def __init__(self, serial):
        self.serial = serial
        
    def run_adb(self, command, wait=True):
        """Run ADB command"""
        cmd = ['adb', '-s', self.serial] + command.split()
        try:
            result = subprocess.run(cmd, capture_output=True, text=True, timeout=30)
            if wait:
                time.sleep(0.5)
            return result.stdout.strip()
        except subprocess.TimeoutExpired:
            print(f"[ERROR] ADB command timeout: {' '.join(cmd)}")
            return ""
    
    def take_screenshot(self, filename):
        """Take screenshot from emulator"""
        path = SCREENSHOT_DIR / f"{self.serial}_{filename}.png"
        result = subprocess.run(
            ['adb', '-s', self.serial, 'shell', 'screencap', '-p'],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE
        )
        if result.returncode == 0:
            with open(path, 'wb') as f:
                f.write(result.stdout)
            print(f"[INFO] Screenshot: {path}")
            return path
        return None
    
    def get_ui_xml(self):
        """Get UI hierarchy XML using uiautomator"""
        xml_path = f"/sdcard/ui_dump_{int(time.time())}.xml"
        self.run_adb(f"shell uiautomator dump {xml_path}")
        local_xml = f"ui_dump_{self.serial}.xml"
        self.run_adb(f"pull {xml_path} {local_xml}")
        self.run_adb(f"shell rm {xml_path}")
        
        if os.path.exists(local_xml):
            with open(local_xml, 'r', encoding='utf-8') as f:
                content = f.read()
            return content
        return None
    
    def find_element_by_text(self, text, exact=False):
        """Find UI element by text in XML"""
        xml_content = self.get_ui_xml()
        if not xml_content:
            return None
        
        try:
            # Parse XML
            root = ET.fromstring(xml_content)
            for node in root.iter():
                if 'text' in node.attrib:
                    node_text = node.attrib['text']
                    if (exact and node_text == text) or (not exact and text.lower() in node_text.lower()):
                        bounds = node.attrib.get('bounds', '')
                        # Extract coordinates from bounds="[x1,y1][x2,y2]"
                        match = re.match(r'\[(\d+),(\d+)\]\[(\d+),(\d+)\]', bounds)
                        if match:
                            x1, y1, x2, y2 = map(int, match.groups())
                            center_x = (x1 + x2) // 2
                            center_y = (y1 + y2) // 2
                            return {'x': center_x, 'y': center_y, 'bounds': bounds, 'text': node_text}
        except Exception as e:
            print(f"[ERROR] XML parsing error: {e}")
        
        return None
    
    def find_element_by_id(self, resource_id):
        """Find UI element by resource ID"""
        xml_content = self.get_ui_xml()
        if not xml_content:
            return None
        
        try:
            root = ET.fromstring(xml_content)
            for node in root.iter():
                if 'resource-id' in node.attrib and resource_id in node.attrib['resource-id']:
                    bounds = node.attrib.get('bounds', '')
                    match = re.match(r'\[(\d+),(\d+)\]\[(\d+),(\d+)\]', bounds)
                    if match:
                        x1, y1, x2, y2 = map(int, match.groups())
                        center_x = (x1 + x2) // 2
                        center_y = (y1 + y2) // 2
                        return {'x': center_x, 'y': center_y, 'bounds': bounds}
        except Exception as e:
            print(f"[ERROR] XML parsing error: {e}")
        
        return None
    
    def tap(self, x, y):
        """Tap at coordinates"""
        self.run_adb(f"shell input tap {x} {y}")
        time.sleep(0.5)
    
    def tap_element(self, element):
        """Tap element found by find_element_*"""
        if element:
            self.tap(element['x'], element['y'])
            return True
        return False
    
    def input_text(self, text):
        """Input text (escapes special characters)"""
        # Clear selection first
        self.run_adb("shell input keyevent KEYCODE_CTRL_LEFT KEYCODE_A")
        time.sleep(0.2)
        # Input text (handle special chars)
        text_escaped = text.replace(' ', '%s').replace('&', '\\&')
        self.run_adb(f'shell input text "{text_escaped}"')
        time.sleep(0.3)
    
    def send_key(self, keycode):
        """Send key event"""
        self.run_adb(f"shell input keyevent {keycode}")
        time.sleep(0.3)
    
    def swipe(self, x1, y1, x2, y2, duration=300):
        """Swipe gesture"""
        self.run_adb(f"shell input swipe {x1} {y1} {x2} {y2} {duration}")
        time.sleep(0.5)


def get_emulator_list():
    """Get list of connected emulators"""
    result = subprocess.run(['adb', 'devices'], capture_output=True, text=True)
    lines = result.stdout.strip().split('\n')[1:]  # Skip header
    emulators = []
    for line in lines:
        if line.strip() and 'emulator-' in line:
            serial = line.split()[0]
            emulators.append(serial)
    return emulators


def login_user(emulator, credentials):
    """Login user on emulator"""
    print(f"[STEP] Logging in {credentials['email']} on {emulator.serial}")
    
    # Take screenshot before login
    emulator.take_screenshot(f"login_start_{credentials['email'].split('@')[0]}")
    
    # Find and tap email/username field
    # Try common field identifiers
    email_field = (emulator.find_element_by_id('email') or 
                   emulator.find_element_by_id('username') or
                   emulator.find_element_by_text('Email', exact=False) or
                   emulator.find_element_by_text('Username', exact=False))
    
    if email_field:
        emulator.tap_element(email_field)
        time.sleep(0.5)
    else:
        # Fallback: tap approximate center of screen (adjust based on your UI)
        print("[WARNING] Email field not found, using approximate coordinates")
        emulator.tap(500, 400)
    
    # Enter email
    emulator.input_text(credentials['email'])
    time.sleep(1)
    
    # Find password field
    password_field = (emulator.find_element_by_id('password') or
                      emulator.find_element_by_text('Password', exact=False))
    
    if password_field:
        emulator.tap_element(password_field)
    else:
        emulator.tap(500, 500)  # Approximate
    
    time.sleep(0.5)
    
    # Enter password
    emulator.input_text(credentials['password'])
    time.sleep(1)
    
    # Find and tap login button
    login_btn = (emulator.find_element_by_text('Login', exact=False) or
                 emulator.find_element_by_text('Sign In', exact=False) or
                 emulator.find_element_by_id('login'))
    
    if login_btn:
        emulator.tap_element(login_btn)
    else:
        emulator.tap(500, 600)  # Approximate
    
    time.sleep(STEP_DELAY)
    emulator.take_screenshot(f"login_complete_{credentials['email'].split('@')[0]}")


def create_shared_ride(emulator, coords):
    """Create shared ride on emulator"""
    print(f"[STEP] Creating shared ride on {emulator.serial}")
    
    # Navigate to shared ride screen (adjust based on your app navigation)
    # This is a template - adapt to your app's UI
    
    emulator.take_screenshot("shared_ride_screen_start")
    
    # Find pickup location field and enter coordinates
    # Adjust these based on your actual UI
    pickup_lat_field = emulator.find_element_by_id('pickup_lat') or emulator.find_element_by_text('Pickup', exact=False)
    if pickup_lat_field:
        emulator.tap_element(pickup_lat_field)
        emulator.input_text(coords['pickup_lat'])
    
    # Similar for other fields...
    # This is a simplified template


def search_for_match(emulator, coords):
    """Search for matching shared ride"""
    print(f"[STEP] Searching for matches on {emulator.serial}")
    emulator.take_screenshot("match_search_start")
    # Implementation similar to create_shared_ride
    pass


def main():
    print("=" * 60)
    print("Automated Shared Ride Testing for Android Emulators")
    print("=" * 60)
    
    # Get available emulators
    emulators = get_emulator_list()
    if len(emulators) < 2:
        print(f"[ERROR] Need at least 2 emulators. Found: {len(emulators)}")
        print("[INFO] Start emulators with: emulator -avd <avd_name> &")
        return
    
    EMULATOR1['serial'] = emulators[0]
    EMULATOR2['serial'] = emulators[1]
    
    print(f"[SUCCESS] Emulator 1: {EMULATOR1['serial']}")
    print(f"[SUCCESS] Emulator 2: {EMULATOR2['serial']}")
    
    em1 = EmulatorController(EMULATOR1['serial'])
    em2 = EmulatorController(EMULATOR2['serial'])
    
    # Unlock devices
    print("[STEP] Unlocking devices...")
    em1.send_key("KEYCODE_WAKEUP")
    em2.send_key("KEYCODE_WAKEUP")
    time.sleep(2)
    em1.send_key("KEYCODE_MENU")
    em2.send_key("KEYCODE_MENU")
    
    # Launch app (parallel)
    print("[STEP] Launching app on both emulators...")
    app_package = "com.ovoride.rider"  # Adjust as needed
    
    with ThreadPoolExecutor(max_workers=2) as executor:
        executor.submit(lambda: em1.run_adb(f"shell monkey -p {app_package} -c android.intent.category.LAUNCHER 1"))
        executor.submit(lambda: em2.run_adb(f"shell monkey -p {app_package} -c android.intent.category.LAUNCHER 1"))
    
    time.sleep(5)
    em1.take_screenshot("01_app_launched")
    em2.take_screenshot("01_app_launched")
    
    # Login (parallel)
    print("[STEP] Logging in users...")
    with ThreadPoolExecutor(max_workers=2) as executor:
        executor.submit(login_user, em1, EMULATOR1)
        executor.submit(login_user, em2, EMULATOR2)
    
    time.sleep(STEP_DELAY)
    
    # Create shared ride on emulator 1
    print("[STEP] Emulator 1 creating shared ride...")
    create_shared_ride(em1, COORDS1)
    time.sleep(STEP_DELAY)
    
    # Search for match on emulator 2
    print("[STEP] Emulator 2 searching for matches...")
    search_for_match(em2, COORDS2)
    time.sleep(STEP_DELAY)
    
    print("[SUCCESS] Test sequence completed!")
    print(f"[INFO] Screenshots saved in: {SCREENSHOT_DIR.absolute()}")


if __name__ == "__main__":
    main()


