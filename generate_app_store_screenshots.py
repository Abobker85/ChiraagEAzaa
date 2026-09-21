import time
import os
import sys
from playwright.sync_api import sync_playwright
from PIL import Image

OUTPUT_DIR = r"d:\ChiraagEAzaa\screenshots"
BASE_URL = "http://127.0.0.1:8089"

def generate_screenshots():
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    
    targets = [
        {
            "device": "iphone",
            "title": "iPhone 6.5-inch",
            "width": 428,
            "height": 926,
            "scale": 3,
            "expected_res": (1284, 2778),
            "tabs": {
                "home": (36, 900),
                "duas": (107, 900),
                "search": (178, 900),
                "tasbih": (250, 900),
                "saved": (321, 900),
            },
            "item_1": (200, 300),
            "tasbih_center": (214, 590),
            "search_box": (200, 85),
        },
        {
            "device": "ipad",
            "title": "iPad 13-inch",
            "width": 1024,
            "height": 1366,
            "scale": 2,
            "expected_res": (2048, 2732),
            "tabs": {
                "home": (85, 1340),
                "duas": (256, 1340),
                "search": (426, 1340),
                "tasbih": (597, 1340),
                "saved": (768, 1340),
            },
            "item_1": (512, 300),
            "tasbih_center": (512, 600),
            "search_box": (512, 85),
        }
    ]

    results = []

    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        
        for tgt in targets:
            print(f"\n=======================================================", flush=True)
            print(f"Generating for {tgt['title']} ({tgt['expected_res'][0]}x{tgt['expected_res'][1]})...", flush=True)
            print(f"=======================================================", flush=True)
            
            context = browser.new_context(
                viewport={"width": tgt["width"], "height": tgt["height"]},
                device_scale_factor=tgt["scale"],
                is_mobile=True,
                has_touch=True,
            )
            page = context.new_page()
            
            # Navigate and wait for DB initialization
            print(f"Loading web app...", flush=True)
            page.goto(BASE_URL, wait_until="load", timeout=45000)
            print(f"Waiting 10s for database & assets to fully ready...", flush=True)
            time.sleep(10)

            # SCREEN 1: Home
            print("Capturing 01_home...", flush=True)
            path_home = os.path.join(OUTPUT_DIR, f"{tgt['device']}_01_home.png")
            page.screenshot(path=path_home)
            results.append(verify_image(path_home, tgt["expected_res"]))

            # SCREEN 2: Duas Hub
            print("Capturing 02_duas_hub...", flush=True)
            page.mouse.click(*tgt["tabs"]["duas"])
            time.sleep(3)
            path_duas = os.path.join(OUTPUT_DIR, f"{tgt['device']}_02_duas_hub.png")
            page.screenshot(path=path_duas)
            results.append(verify_image(path_duas, tgt["expected_res"]))

            # SCREEN 3: Recitation Reader (Ayat Al Kursi)
            print("Capturing 03_recitation_reader...", flush=True)
            page.mouse.click(*tgt["item_1"])
            time.sleep(3)
            path_reader = os.path.join(OUTPUT_DIR, f"{tgt['device']}_03_recitation_reader.png")
            page.screenshot(path=path_reader)
            results.append(verify_image(path_reader, tgt["expected_res"]))

            # Go back to Duas hub
            print("Returning to Duas hub...", flush=True)
            page.mouse.click(30, 45) # Back arrow in AppBar
            time.sleep(2)

            # SCREEN 4: Digital Tasbih
            print("Capturing 04_digital_tasbih...", flush=True)
            page.mouse.click(*tgt["tabs"]["tasbih"])
            time.sleep(2)
            # Tap tasbih button a few times to show count progress
            for _ in range(7):
                page.mouse.click(*tgt["tasbih_center"])
                time.sleep(0.2)
            path_tasbih = os.path.join(OUTPUT_DIR, f"{tgt['device']}_04_digital_tasbih.png")
            page.screenshot(path=path_tasbih)
            results.append(verify_image(path_tasbih, tgt["expected_res"]))

            # SCREEN 5: Search
            print("Capturing 05_search...", flush=True)
            page.mouse.click(*tgt["tabs"]["search"])
            time.sleep(2)
            page.mouse.click(*tgt["search_box"])
            time.sleep(0.5)
            page.keyboard.type("Ali")
            time.sleep(2)
            path_search = os.path.join(OUTPUT_DIR, f"{tgt['device']}_05_search.png")
            page.screenshot(path=path_search)
            results.append(verify_image(path_search, tgt["expected_res"]))

            context.close()

        browser.close()

    print("\n================== SUMMARY ==================", flush=True)
    all_passed = True
    for r in results:
        status = "PASSED" if r["valid"] else "FAILED"
        print(f"[{status}] {r['filename']}: {r['actual_size']} (Expected: {r['expected_size']})", flush=True)
        if not r["valid"]:
            all_passed = False

    if all_passed:
        print("\nAll screenshots generated and verified to exact App Store specifications!", flush=True)
    else:
        print("\nWarning: Some screenshots had dimension mismatches.", flush=True)

def verify_image(path, expected):
    img = Image.open(path)
    valid = (img.size == expected)
    return {
        "filename": os.path.basename(path),
        "actual_size": img.size,
        "expected_size": expected,
        "valid": valid
    }

if __name__ == "__main__":
    generate_screenshots()
