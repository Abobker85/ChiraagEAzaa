import time
import sys
from playwright.sync_api import sync_playwright
from PIL import Image

def test_screen():
    print("Starting Playwright...", flush=True)
    with sync_playwright() as p:
        iphone_device = {
            "viewport": {"width": 428, "height": 926},
            "device_scale_factor": 3,
            "is_mobile": True,
            "has_touch": True,
            "user_agent": "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1"
        }
        
        browser = p.chromium.launch(headless=True)
        context = browser.new_context(**iphone_device)
        page = context.new_page()
        
        print("Navigating to http://127.0.0.1:8787 ...", flush=True)
        page.goto("http://127.0.0.1:8787", wait_until="load", timeout=30000)
        
        print("Waiting 10 seconds for Flutter engine & assets to fully render...", flush=True)
        time.sleep(10)
        
        # Save screenshot
        page.screenshot(path="screenshots/test_iphone_home.png")
        print("Screenshot saved to screenshots/test_iphone_home.png", flush=True)
        
        # Check image dimensions
        img = Image.open("screenshots/test_iphone_home.png")
        print(f"Image size: {img.size} (Expected: 1284, 2778)", flush=True)
        
        browser.close()
        print("Done!", flush=True)

if __name__ == "__main__":
    test_screen()
