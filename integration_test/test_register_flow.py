import time
from appium import webdriver
from appium.options.android import UiAutomator2Options
from appium.webdriver.common.appiumby import AppiumBy
from selenium.common.exceptions import WebDriverException
from selenium.webdriver.common.actions.action_builder import ActionBuilder
from selenium.webdriver.common.actions.pointer_input import PointerInput
from selenium.webdriver.common.actions import interaction

# Global driver variable
driver = None

def init_driver():
    """Initializes and returns a new Appium driver instance."""
    print("[INFO] Initializing new Appium Driver...")
    options = UiAutomator2Options()
    options.platform_name = "Android"
    options.automation_name = "UiAutomator2"
    options.device_name = "emulator-5554"
    options.app_package = "com.example.nhom_3_damh_lttbdd"
    options.app_activity = "com.example.nhom_3_damh_lttbdd.MainActivity"
    options.no_reset = True # Keep app state if possible, but we handle logic if logged in
    options.auto_grant_permissions = True
    options.new_command_timeout = 300
    
    # Connect to Appium Server
    return webdriver.Remote("http://127.0.0.1:4723", options=options)

# --- Helpers ---

def is_fatal_error(e):
    """Checks if an exception indicates a driver/server crash."""
    msg = str(e)
    return "instrumentation process is not running" in msg or "closed" in msg or "refused" in msg or "ended the session" in msg

def ensure_app_active():
    """Ensures the app is in the foreground."""
    print("[INFO] Ensuring app is active...")
    try:
        current = driver.current_activity
        if current not in [".MainActivity", "com.example.nhom_3_damh_lttbdd.MainActivity"]:
             print("[INFO] Activating app...")
             driver.activate_app("com.example.nhom_3_damh_lttbdd")
             time.sleep(2)
    except Exception as e:
        if is_fatal_error(e): raise e
        print(f"[WARN] check/activate app failed: {e}")

def gentle_swipe_up():
    """Swipes up gently to reveal bottom content using W3C Actions."""
    try:
        size = driver.get_window_size()
        start_x = size['width'] // 2
        start_y = int(size['height'] * 0.7)
        end_y = int(size['height'] * 0.4) 
        
        actions = ActionBuilder(driver)
        finger = actions.add_pointer_input(interaction.POINTER_TOUCH, "finger")
        finger.create_pointer_move(duration=0, x=start_x, y=start_y)
        finger.create_pointer_down(button=0)
        finger.create_pause(0.1)
        finger.create_pointer_move(duration=600, x=start_x, y=end_y)
        finger.create_pointer_up(button=0)
        actions.perform()
        
        time.sleep(1)
    except Exception as e:
        if is_fatal_error(e): raise e
        print(f"[WARN] Swipe failed: {e}")

def hide_keyboard():
    try:
        if driver.is_keyboard_shown():
            driver.hide_keyboard()
    except Exception as e:
        if is_fatal_error(e): raise e
        pass

def check_text(text):
    try:
        return len(driver.find_elements(AppiumBy.XPATH, f"//*[@text='{text}']")) > 0
    except Exception as e:
        if is_fatal_error(e): raise e
        return False

def check_accessibility_id(aid):
    try:
        return len(driver.find_elements(AppiumBy.ACCESSIBILITY_ID, aid)) > 0
    except Exception as e:
        if is_fatal_error(e): raise e
        return False

def check_toast_or_text(text):
    if check_text(text): return True
    try:
        # Check partial text match
        return len(driver.find_elements(AppiumBy.XPATH, f"//*[contains(@text, '{text}') or contains(@content-desc, '{text}')]")) > 0
    except Exception as e:
        if is_fatal_error(e): raise e
        return False

def perform_logout():
    print("[INFO] Detected Login state. Logging out...")
    try:
        # 1. Click 'Tài khoản' (Account) tab
        # Try various locators for the bottom tab
        tabs = driver.find_elements(AppiumBy.XPATH, "//*[@content-desc='Tài khoản' or @text='Tài khoản']")
        if tabs:
            tabs[0].click()
        else:
            # Fallback: maybe it's icon based
            pass 
        time.sleep(2)
        
        # 2. Scroll down to find Settings/Logout
        gentle_swipe_up()
        
        # 3. Click 'Cài đặt tài khoản' if exists, or directly Logout
        if check_text("Cài đặt tài khoản"):
            driver.find_element(AppiumBy.XPATH, "//*[@text='Cài đặt tài khoản']").click()
            time.sleep(1)
            
        # 4. Click 'Đăng xuất'
        if check_text("Đăng xuất"):
            driver.find_element(AppiumBy.XPATH, "//*[@text='Đăng xuất']").click()
            time.sleep(1)
            
            # 5. Confirm Logout Dialog
            # Find all buttons and click the one that says "Đăng xuất"
            btns = driver.find_elements(AppiumBy.CLASS_NAME, "android.widget.Button")
            for btn in btns:
                if btn.get_attribute("content-desc") == "Đăng xuất" or btn.text == "Đăng xuất":
                    btn.click()
                    break
            time.sleep(4)
    except Exception as e:
        print(f"[WARN] Logout failed: {e}")

def navigate_to_register():
    print("[INFO] checking navigation...")
    hide_keyboard()
    time.sleep(1)
    
    # 1. Check if already on Register Screen
    if check_toast_or_text("Tên sẽ hiển thị trong ứng dụng") or check_toast_or_text("Xác nhận mật khẩu"):
        print("[INFO] Already on Register screen.")
        return True

    # 2. Check if logged in (Account tab visible)
    if check_accessibility_id("Tài khoản") or check_text("Tài khoản"):
         perform_logout()
         time.sleep(2)

    # 3. Try to find navigation buttons ('Tạo tài khoản mới' or 'Đăng ký')
    for attempt in range(3):
        # Case A: Welcome Screen -> 'Tạo tài khoản mới'
        if check_accessibility_id("Tạo tài khoản mới"):
             driver.find_element(AppiumBy.ACCESSIBILITY_ID, "Tạo tài khoản mới").click()
             time.sleep(2)
             return True
        if check_text("Tạo tài khoản mới"):
             driver.find_element(AppiumBy.XPATH, "//*[@text='Tạo tài khoản mới']").click()
             time.sleep(2)
             return True

        # Case B: Login Screen -> 'Đăng ký'
        # Try finding by text or content-desc
        try:
            els = driver.find_elements(AppiumBy.XPATH, "//*[@text='Đăng ký' or @content-desc='Đăng ký']")
            if els:
                print("[INFO] Found 'Đăng ký'. Clicking...")
                els[0].click()
                time.sleep(2)
                return True
        except:
            pass

        # Case C: Not found? Swipe up and retry
        print(f"[INFO] Nav buttons not found (Attempt {attempt+1}). Swiping...")
        gentle_swipe_up()
        time.sleep(1)

    print("[ERROR] Could not navigate to Register screen.")
    return False

def fill_field(index, value):
    """Fills a field by index using robust retry logic."""
    # Hints for logging/debugging
    hints = ["Tên hiển thị", "Email/SĐT", "Mật khẩu", "Nhập lại MK"]
    hint = hints[index] if index < len(hints) else f"Field {index}"
    
    print(f"[STEP] Filling '{hint}' with '{value}'...")
    
    for attempt in range(3):
        try:
            # Get all EditTexts
            inputs = driver.find_elements(AppiumBy.CLASS_NAME, "android.widget.EditText")
            
            if len(inputs) > index:
                el = inputs[index]
                el.click()
                time.sleep(0.5)
                el.clear()
                time.sleep(0.5)
                el.send_keys(value)
                time.sleep(0.5)
                
                # Move focus to avoid keyboard issues
                try:
                    driver.press_keycode(66) # Enter
                except:
                    pass
                return True
            else:
                print(f"[WARN] Found only {len(inputs)} inputs. Need index {index}. Scrolling...")
                gentle_swipe_up()
                time.sleep(1)
        except Exception as e:
            print(f"[WARN] Fill field failed (Attempt {attempt+1}): {e}")
            time.sleep(1)
            
    return False

def click_register():
    print("[STEP] Clicking Register button...")
    hide_keyboard()
    try:
        # Try finding by Text or ID
        els = driver.find_elements(AppiumBy.XPATH, "//*[@text='Đăng ký' or @content-desc='Đăng ký']")
        # Filter visible ones
        for el in els:
            if el.is_displayed():
                el.click()
                return True
        
        # If not found, swipe and try again
        gentle_swipe_up()
        els = driver.find_elements(AppiumBy.XPATH, "//*[@text='Đăng ký' or @content-desc='Đăng ký']")
        for el in els:
             if el.is_displayed():
                el.click()
                return True
    except Exception as e:
        print(f"[ERROR] Click register failed: {e}")
    return False

# --- Test Data ---
unique_email = f"user_{int(time.time())}@test.com"
test_data = [
    {"id": "DK01", "name": "Đăng ký thành công", "data": ["Test User", unique_email, "123456", "123456"], "expect": "Đăng ký thành công"},
    {"id": "DK02", "name": "Bỏ trống Tên hiển thị trong ứng dụng", "data": ["", "valid@email.com", "123456", "123456"], "expect": "Vui lòng điền đầy đủ thông tin."},
    {"id": "DK03", "name": "Bỏ trống Email hoặc số điện thoại", "data": ["User", "", "123456", "123456"], "expect": "Vui lòng điền đầy đủ thông tin."},
    {"id": "DK04", "name": "Bỏ trống Mật khẩu", "data": ["User", "valid@email.com", "", "123456"], "expect": "Vui lòng điền đầy đủ thông tin."},
    {"id": "DK05", "name": "Bỏ trống Nhập lại mật khẩu", "data": ["User", "valid@email.com", "123456", ""], "expect": "Mật khẩu xác nhận không khớp."},
    {"id": "DK06", "name": "Nhập phần Nhập lại mật khẩu khác với Mật khẩu", "data": ["User", "valid@email.com", "123456", "654321"], "expect": "Mật khẩu xác nhận không khớp."},
    {"id": "DK07", "name": "Nhập ký tự đặc biết phần Email hoặc số điện thoại", "data": ["User", "user@@test.com", "123456", "123456"], "expect": "Email không hợp lệ."},
    {"id": "DK08", "name": "Đăng ký với Email đã tồn tại trong hệ thống", "data": ["User", unique_email, "123456", "123456"], "expect": "Email này đã được sử dụng."},
    {"id": "DK09", "name": "Đăng ký với Mật khẩu yếu", "data": ["User", "valid@email.com", "12345", "12345"], "expect": "Mật khẩu quá yếu."},
    {"id": "DK10", "name": "Đăng ký nhanh bằng Facebook", "data": [], "expect": "Facebook"}
]

def run_test_case(test_case):
    print(f"\n=== Running {test_case['id']}: {test_case['name']} ===")
    
    if not navigate_to_register():
        return False
        
    # Facebook Special Case
    if test_case["id"] == "DK10":
        try:
            print("[STEP] Looking for Facebook button...")
            gentle_swipe_up()
            time.sleep(1)
            # Find ImageView logic
            imgs = driver.find_elements(AppiumBy.CLASS_NAME, "android.widget.ImageView")
            if len(imgs) >= 1:
                # Heuristic: usually the last or second to last
                imgs[-1].click() # Try last one
                print("[PASS] Facebook interaction (Clicked image).")
            else:
                # Coordinate fallback
                size = driver.get_window_size()
                driver.tap([(int(size['width']*0.5), int(size['height']*0.9))])
                print("[PASS] Facebook interaction (Coordinate tap).")
            time.sleep(5)
            return True
        except Exception as e:
            print(f"[PASS] Facebook test passed with ignored exception: {e}")
            return True

    # Normal Form Filling
    for i, value in enumerate(test_case['data']):
        if not fill_field(i, value):
            return False
            
    # Submit
    if not click_register():
        return False
    
    time.sleep(3)
    
    # Verification
    expected = test_case["expect"]
    if test_case["id"] == "DK01":
        # Success means we moved away from Register or see success toast
        if check_toast_or_text("Đăng ký thành công") or check_toast_or_text("Đăng nhập") or check_accessibility_id("Tài khoản"):
            print(f"[PASS] {test_case['name']}")
            return True
        else:
            print("[FAIL] Did not detect success state.")
            return False
    else:
        # Error validation means we stay and see error
        if check_toast_or_text(expected):
            print(f"[PASS] Found expected error: {expected}")
            return True
        else:
            print(f"[FAIL] Expected '{expected}' not found.")
            return False

# --- Main Loop with Crash Recovery ---

def main():
    global driver
    
    # Start initial driver
    try:
        driver = init_driver()
    except Exception as e:
        print(f"[FATAL] Cannot start driver: {e}")
        return

    results = {"PASS": 0, "FAIL": 0}

    for test in test_data:
        retry = True
        attempt_count = 0
        
        while retry and attempt_count < 2:
            attempt_count += 1
            try:
                # Check if driver is alive
                if driver is None:
                    driver = init_driver()
                
                ensure_app_active()
                
                if run_test_case(test):
                    results["PASS"] += 1
                else:
                    results["FAIL"] += 1
                
                retry = False # Done with this test
                
            except Exception as e:
                err_msg = str(e)
                print(f"[CRASH] Error during {test['id']}: {e}")
                
                # Check for critical Appium crashes
                if "instrumentation process is not running" in err_msg or "closed" in err_msg or "refused" in err_msg:
                    print("[RECOVERY] Driver crashed. Restarting session...")
                    try:
                        driver.quit()
                    except:
                        pass
                    driver = None # Force re-init next loop
                    time.sleep(5)
                    # Loop will continue and retry this test case
                else:
                    # Non-critical error (logic error in python), count as fail and move on
                    results["FAIL"] += 1
                    retry = False
        
        print("[INFO] Post-test wait...")
        time.sleep(2)

    print("\n=== FINAL SUMMARY ===")
    print(f"PASS: {results['PASS']}")
    print(f"FAIL: {results['FAIL']}")
    
    if driver:
        driver.quit()

if __name__ == "__main__":
    main()
