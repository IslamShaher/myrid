#!/usr/bin/env python3
"""
Emulator Monitor - Automated Screenshot and XML Capture Tool
Monitors emulators and captures screenshots/XML on demand or continuously
NO automation of actions - just monitoring and capture
"""

import subprocess
import time
import os
import xml.etree.ElementTree as ET
from pathlib import Path
from datetime import datetime
import argparse
import sys

class EmulatorMonitor:
    def __init__(self, serial, output_dir):
        self.serial = serial
        self.output_dir = Path(output_dir)
        self.screenshot_dir = self.output_dir / "screenshots"
        self.xml_dir = self.output_dir / "xml_dumps"
        self.parsed_dir = self.output_dir / "parsed_xml"
        
        # Create directories
        for dir_path in [self.screenshot_dir, self.xml_dir, self.parsed_dir]:
            dir_path.mkdir(parents=True, exist_ok=True)
    
    def run_adb(self, command):
        """Run ADB command"""
        cmd = ['adb', '-s', self.serial] + command.split()
        try:
            result = subprocess.run(cmd, capture_output=True, text=True, timeout=10)
            return result.stdout.strip()
        except subprocess.TimeoutExpired:
            print(f"[ERROR] ADB command timeout: {' '.join(cmd)}")
            return ""
        except Exception as e:
            print(f"[ERROR] ADB error: {e}")
            return ""
    
    def capture_screenshot(self, filename):
        """Capture screenshot from emulator"""
        path = self.screenshot_dir / f"{self.serial}_{filename}.png"
        
        try:
            # Method 1: exec-out (more reliable)
            result = subprocess.run(
                ['adb', '-s', self.serial, 'exec-out', 'screencap', '-p'],
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                timeout=10
            )
            
            if result.returncode == 0 and len(result.stdout) > 0:
                with open(path, 'wb') as f:
                    f.write(result.stdout)
                print(f"[INFO] Screenshot: {path}")
                return path
        except Exception as e:
            print(f"[ERROR] Screenshot failed: {e}")
        
        return None
    
    def capture_xml(self, filename):
        """Capture UI hierarchy XML"""
        timestamp = int(time.time())
        xml_path = f"/sdcard/ui_dump_{timestamp}.xml"
        local_xml = self.xml_dir / f"{self.serial}_{filename}.xml"
        
        try:
            # Dump UI hierarchy
            self.run_adb(f"shell uiautomator dump {xml_path}")
            time.sleep(0.5)
            
            # Pull XML file
            result = subprocess.run(
                ['adb', '-s', self.serial, 'pull', xml_path, str(local_xml)],
                capture_output=True,
                timeout=10
            )
            
            # Clean up remote file
            self.run_adb(f"shell rm {xml_path}")
            
            if local_xml.exists():
                print(f"[INFO] XML dump: {local_xml}")
                
                # Parse XML
                self.parse_xml_to_text(local_xml, filename)
                
                return local_xml
        except Exception as e:
            print(f"[ERROR] XML capture failed: {e}")
        
        return None
    
    def parse_xml_to_text(self, xml_path, filename):
        """Parse XML to readable text format"""
        parsed_path = self.parsed_dir / f"{self.serial}_{filename}_parsed.txt"
        
        try:
            tree = ET.parse(xml_path)
            root = tree.getroot()
            
            output = []
            output.append("=" * 80)
            output.append(f"UI Hierarchy - {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
            output.append("=" * 80)
            output.append("")
            
            def process_node(node, depth=0):
                indent = "  " * depth
                attrs = []
                
                # Extract attributes
                text = node.get('text', '')
                resource_id = node.get('resource-id', '')
                content_desc = node.get('content-desc', '')
                class_name = node.get('class', '')
                bounds = node.get('bounds', '')
                clickable = node.get('clickable', 'false')
                checkable = node.get('checkable', 'false')
                
                if text:
                    attrs.append(f"text='{text}'")
                if resource_id:
                    attrs.append(f"id='{resource_id}'")
                if content_desc:
                    attrs.append(f"desc='{content_desc}'")
                if class_name:
                    attrs.append(f"class='{class_name}'")
                if bounds:
                    attrs.append(f"bounds='{bounds}'")
                    # Extract center coordinates
                    match = re.match(r'\[(\d+),(\d+)\]\[(\d+),(\d+)\]', bounds)
                    if match:
                        x1, y1, x2, y2 = map(int, match.groups())
                        center_x = (x1 + x2) // 2
                        center_y = (y1 + y2) // 2
                        attrs.append(f"center=({center_x}, {center_y})")
                
                if clickable == 'true':
                    attrs.append("[CLICKABLE]")
                if checkable == 'true':
                    attrs.append("[CHECKABLE]")
                
                line = f"{indent}<{class_name}"
                if attrs:
                    line += " " + " ".join(attrs)
                line += ">"
                output.append(line)
                
                if text:
                    output.append(f"{indent}  Text: {text}")
                
                # Process children
                for child in node:
                    process_node(child, depth + 1)
            
            process_node(root)
            
            with open(parsed_path, 'w', encoding='utf-8') as f:
                f.write('\n'.join(output))
            
            print(f"[INFO] Parsed XML: {parsed_path}")
            return parsed_path
            
        except Exception as e:
            print(f"[ERROR] XML parsing failed: {e}")
            return None
    
    def find_elements(self, xml_path, search_text=None, search_id=None):
        """Find elements in XML by text or resource ID"""
        results = []
        
        try:
            tree = ET.parse(xml_path)
            root = tree.getroot()
            
            def search_node(node):
                text = node.get('text', '')
                resource_id = node.get('resource-id', '')
                bounds = node.get('bounds', '')
                
                match = False
                if search_text and search_text.lower() in text.lower():
                    match = True
                if search_id and search_id in resource_id:
                    match = True
                
                if match:
                    info = {
                        'text': text,
                        'resource_id': resource_id,
                        'bounds': bounds,
                        'clickable': node.get('clickable', 'false')
                    }
                    
                    # Extract center coordinates
                    match_coords = re.match(r'\[(\d+),(\d+)\]\[(\d+),(\d+)\]', bounds)
                    if match_coords:
                        x1, y1, x2, y2 = map(int, match_coords.groups())
                        info['center_x'] = (x1 + x2) // 2
                        info['center_y'] = (y1 + y2) // 2
                    
                    results.append(info)
                
                for child in node:
                    search_node(child)
            
            search_node(root)
            
        except Exception as e:
            print(f"[ERROR] Element search failed: {e}")
        
        return results


def get_emulator_list():
    """Get list of connected emulators"""
    try:
        result = subprocess.run(['adb', 'devices'], capture_output=True, text=True)
        lines = result.stdout.strip().split('\n')[1:]  # Skip header
        emulators = []
        for line in lines:
            if line.strip() and 'emulator-' in line:
                serial = line.split()[0]
                emulators.append(serial)
        return emulators
    except Exception as e:
        print(f"[ERROR] Failed to get emulator list: {e}")
        return []


def main():
    parser = argparse.ArgumentParser(description='Monitor Android emulators - capture screenshots and XML')
    parser.add_argument('-s', '--serials', nargs='+', help='Emulator serials (default: auto-detect)')
    parser.add_argument('-i', '--interval', type=int, default=2, help='Capture interval in seconds (continuous mode)')
    parser.add_argument('-o', '--output', default=None, help='Output directory')
    parser.add_argument('-c', '--continuous', action='store_true', help='Continuous monitoring mode')
    parser.add_argument('--xml-only', action='store_true', help='Capture XML only')
    parser.add_argument('--screenshot-only', action='store_true', help='Capture screenshots only')
    
    args = parser.parse_args()
    
    # Output directory
    if args.output:
        output_dir = Path(args.output)
    else:
        output_dir = Path(f"emulator_monitor_{datetime.now().strftime('%Y%m%d_%H%M%S')}")
    
    print("=" * 60)
    print("Emulator Monitor - Screenshot & XML Capture Tool")
    print("=" * 60)
    print()
    
    # Get emulators
    if args.serials:
        emulator_serials = args.serials
    else:
        print("[INFO] Detecting emulators...")
        emulator_serials = get_emulator_list()
    
    if not emulator_serials:
        print("[ERROR] No emulators found. Start emulators first.")
        print("[INFO] Check with: adb devices")
        sys.exit(1)
    
    print(f"[SUCCESS] Monitoring {len(emulator_serials)} emulator(s):")
    for serial in emulator_serials:
        print(f"  - {serial}")
    
    print()
    print(f"[INFO] Output directory: {output_dir.absolute()}")
    print()
    
    # Create monitors
    monitors = [EmulatorMonitor(serial, output_dir) for serial in emulator_serials]
    
    def capture_all(suffix=""):
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        filename = f"{timestamp}_{suffix}" if suffix else timestamp
        
        for monitor in monitors:
            print(f"[INFO] Capturing from {monitor.serial}...")
            if not args.xml_only:
                monitor.capture_screenshot(filename)
            if not args.screenshot_only:
                monitor.capture_xml(filename)
    
    if args.continuous:
        print(f"[INFO] Continuous mode: Capturing every {args.interval} seconds")
        print("[INFO] Press Ctrl+C to stop")
        print()
        
        counter = 0
        try:
            while True:
                counter += 1
                print(f"\n[Capture #{counter}] {datetime.now().strftime('%H:%M:%S')}")
                capture_all(f"auto_{counter}")
                time.sleep(args.interval)
        except KeyboardInterrupt:
            print("\n[INFO] Monitoring stopped.")
    else:
        print("[INFO] Manual capture mode")
        print("[INFO] Press Enter to capture, or type 'q' to quit")
        print()
        
        counter = 0
        while True:
            try:
                user_input = input("Capture (Enter) or Quit (q): ").strip()
                if user_input.lower() == 'q':
                    break
                
                counter += 1
                print()
                capture_all(f"manual_{counter}")
                print()
            except KeyboardInterrupt:
                break
    
    print(f"\n[SUCCESS] Monitoring complete. Files saved in: {output_dir.absolute()}")


if __name__ == "__main__":
    import re
    main()




