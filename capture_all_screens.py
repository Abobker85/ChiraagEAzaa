import sys
import time
import os
from playwright.sync_api import sync_playwright
from PIL import Image

def capture_suite(base_url="http://127.0.0.1:8089"):
    os.makedirs("screenshots", exist_ok=True)
    
    devices = [
        {
            "name": "iphone",
            "label": "iPhone 6.5-inch (1284 x 2778)",
            "width": 428,
            "height": 926,
            "scale": 3,
            "expected_size": (1284, 2778),
            # In 428 width, bottom bar has 6 tabs:
            # Home ~ 35, Duas ~ 107, Search ~ 178, Tasbih ~ 250, Saved ~ 321, Settings ~ 393
            # Bottom bar Y is roughly 900
            "tab_y": 900,
            "tabs": {
                "home": (35, 900),
                "duas": (107, 900),
                "search": (178, 900),
                "tasbih": (250, 900),
                "saved": (321, 900),
            },
            "dua_first_item": (200, 260), # Coordinates in DuaHubScreen list
            "tasbih_center": (214, 500), # Center of Tasbih circular button
        },
        {
            "name": "ipad",
            "label": "iPad 13-inch (2048 x 2732)",
            "width": 1024,
            "height": 1366,
            "scale": 2,
            "expected_size": (2048, 2732),
            # In 1024 width, bottom bar has 6 tabs:
            # Home ~ 85, Duas ~ 256, Search ~ 426, Tasbih ~ 597, Saved ~ 768, Settings ~ 938
            # Bottom bar Y is roughly 1330
            "tab_y": 1330,
            "tabs": {
                "home": (85, 1330),
                "duas": (256, 1330),
                "search": (426, 1330),
                "tasbih": (597, 1330),
                "saved": (768, 1330),
            },
            "dua_first_item": (400, 260),
            "tasbih_center": (512, 700),
        }
    ]

    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        
        for dev in devices:
            print(f"\n==========================================", flush=True)
            print(f"Starting captures for {dev['label']} ...", flush=True)
            print(f"==========================================", flush=True)
            
            context = browser.new_context(
                viewport={"width": dev["width"], "height": dev["height"]},
                device_scale_factor=dev["scale"],
                is_mobile=True,
                has_touch=True,
            )
            page = context.new_page()
            
            # 1. Open app
            print(f"Loading {base_url} ...", flush=True)
            page.goto(base_url, wait_until="load", timeout=45000)
            print("Waiting 12 seconds for database and assets to load...", flush=True)
            time.sleep(12)
            
            # Enable Flutter accessibility tree if present
            try:
                placeholder = page.locator("flt-semantics-placeholder")
                if placeholder.count() > 0:
                    placeholder.click()
                    time.sleep(2)
            except Exception as e:
                print("Semantics note:", e, flush=True)

            # SCREEN 1: Home Screen
            print("Capturing 01: Home Screen...", flush=True)
            time.sleep(2)
            file_01 = f"screenshots/{dev['name']}_01_home.png"
            page.screenshot(path=file_01)
            img1 = Image.open(file_01)
            print(f"  -> Saved {file_01} | Size: {img1.size}", flush=True)
            
            # SCREEN 2: Dua Hub Screen
            print("Navigating to Duas Tab...", flush=True)
            tab_dua_x, tab_y = dev["tabs"]["duas"]
            page.mouse.click(tab_dua_x, tab_y)
            time.sleep(4)
            file_02 = f"screenshots/{dev['name']}_02_duas_hub.png"
            page.screenshot(path=file_02)
            img2 = Image.open(file_02)
            print(f"  -> Saved {file_02} | Size: {img2.size}", flush=True)
            
            # SCREEN 3: Recitation Reader (click on first Dua item)
            print("Opening Recitation Reader (First Dua item)...", flush=True)
            item_x, item_y = dev["dua_first_item"]
            page.mouse.click(item_x, item_y)
            time.sleep(4)
            file_03 = f"screenshots/{dev['name']}_03_recitation_reader.png"
            page.screenshot(path=file_03)
            img3 = Image.open(file_03)
            print(f"  -> Saved {file_03} | Size: {img3.size}", flush=True)
            
            # Go back from reader
            print("Going back to hub...", flush=True)
            # Click back button at top-left (approx x=30, y=50) or hit Escape / history back
            page.mouse.click(30, 50)
            time.sleep(2)
            
            # SCREEN 4: Digital Tasbih
            print("Navigating to Tasbih Tab...", flush=True)
            tab_tasbih_x, tab_y = dev["tabs"]["tasbih"]
            page.mouse.click(tab_tasbih_x, tab_y)
            time.sleep(3)
            # Tap counter a few times for visual beads progress
            t_cx, t_cy = dev["tasbih_center"]
            for _ in range(7):
                page.mouse.click(t_cx, t_cy)
                time.sleep(0.3)
            file_04 = f"screenshots/{dev['name']}_04_digital_tasbih.png"
            page.screenshot(path=file_04)
            img4 = Image.open(file_04)
            print(f"  -> Saved {file_04} | Size: {img4.size}", flush=True)
            
            # SCREEN 5: Search
            print("Navigating to Search Tab...", flush=True)
            tab_search_x, tab_y = dev["tabs"]["search"]
            page.mouse.click(tab_search_x, tab_y)
            time.sleep(3)
            # Type something into search
            # Search bar is roughly near top (x=dev['width']//2, y=80)
            page.mouse.click(dev["width"] // 2, 80)
            time.sleep(0.5)
            page.keyboard.type("Karbala")
            time.sleep(3)
            file_05 = f"screenshots/{dev['name']}_05_search.png"
            page.screenshot(path=file_05)
            img5 = Image.open(file_05)
            print(f"  -> Saved {file_05} | Size: {img5.size}", flush=True)
            
            context.close()
            
        browser.close()
    print("\nAll screenshots captured successfully!", flush=True)

if __name__ == "__main__":
    capture_suite()
