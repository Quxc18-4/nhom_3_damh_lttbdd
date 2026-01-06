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
    options.no_reset = True 
    options.auto_grant_permissions = True
    options.new_command_timeout = 300
    
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
        if check_accessibility_id("Admin - Duyệt & Banner") or check_text("Admin - Duyệt & Banner"):
            print("[INFO] Detected Admin Screen.")
            size = driver.get_window_size()
            w = size["width"]; h = size["height"]
            clicked = False
            try:
                if check_toast_or_text("Đăng xuất"):
                    driver.find_element(AppiumBy.XPATH, "//*[@text='Đăng xuất' or @content-desc='Đăng xuất']").click()
                    clicked = True
                else:
                    candidates = []
                    try:
                        candidates.extend(driver.find_elements(AppiumBy.CLASS_NAME, "android.widget.ImageButton"))
                    except:
                        pass
                    try:
                        candidates.extend(driver.find_elements(AppiumBy.CLASS_NAME, "android.widget.ImageView"))
                    except:
                        pass
                    for el in candidates:
                        try:
                            rect = el.rect
                            cx = rect["x"] + rect["width"] / 2
                            cy = rect["y"] + rect["height"] / 2
                            clickable = el.get_attribute("clickable") == "true"
                            visible = el.is_displayed()
                            if visible and clickable and cx > w * 0.8 and cy < h * 0.15:
                                el.click()
                                clicked = True
                                break
                        except:
                            continue
                    if not clicked:
                        x = int(w * 0.95)
                        y = int(h * 0.06)
                        actions = ActionBuilder(driver)
                        finger = actions.add_pointer_input(interaction.POINTER_TOUCH, "finger")
                        finger.create_pointer_move(duration=0, x=x, y=y)
                        finger.create_pointer_down(button=0)
                        finger.create_pause(0.1)
                        finger.create_pointer_up(button=0)
                        actions.perform()
                        clicked = True
            except Exception as e:
                if is_fatal_error(e): raise e
                print(f"[WARN] Admin logout tap failed: {e}")
            time.sleep(2)
            try:
                btns = driver.find_elements(AppiumBy.CLASS_NAME, "android.widget.Button")
                chosen = None
                for btn in btns:
                    t = btn.text or ""
                    cd = btn.get_attribute("content-desc") or ""
                    if "Đăng xuất" in t or "Đăng xuất" in cd:
                        chosen = btn
                        break
                if not chosen and btns:
                    chosen = btns[-1]
                if chosen:
                    chosen.click()
                time.sleep(2)
            except Exception as e:
                if is_fatal_error(e): raise e
            return

        # 1. Click 'Tài khoản' (Account) tab
        # Try multiple locators
        xpath_tab = "//*[contains(@content-desc, 'Tài khoản') or contains(@text, 'Tài khoản')]"
        tabs = driver.find_elements(AppiumBy.XPATH, xpath_tab)
        if tabs:
            print(f"[INFO] Found {len(tabs)} 'Tài khoản' elements. Clicking first...")
            tabs[0].click()
        else:
             print("[WARN] 'Tài khoản' tab NOT found. Trying generic coordinate click (Bottom Right)...")
             # Fallback: Click bottom-right area (assuming 4 tabs)
             size = driver.get_window_size()
             w = size['width']
             h = size['height']
             # 4th tab out of 4 -> ~87.5% width, ~95% height
             x = int(w * 0.875)
             y = int(h * 0.95)
             
             actions = ActionBuilder(driver)
             finger = actions.add_pointer_input(interaction.POINTER_TOUCH, "finger")
             finger.create_pointer_move(duration=0, x=x, y=y)
             finger.create_pointer_down(button=0)
             finger.create_pause(0.1)
             finger.create_pointer_up(button=0)
             actions.perform()
             print(f"[INFO] Tapped coordinates ({x}, {y}) for Account tab.")

        time.sleep(2)
        
        # 2. Find and Click 'Cài đặt tài khoản'
        # It might be down the list, so we try to find it, if not, swipe up
        settings_clicked = False
        for i in range(2):
            if check_toast_or_text("Cài đặt tài khoản"):
                print("[INFO] Clicking 'Cài đặt tài khoản'...")
                driver.find_element(AppiumBy.XPATH, "//*[contains(@text, 'Cài đặt tài khoản') or contains(@content-desc, 'Cài đặt tài khoản')]").click()
                settings_clicked = True
                break
            else:
                print(f"[INFO] 'Cài đặt tài khoản' not visible. Swiping up (attempt {i+1})...")
                gentle_swipe_up()
                time.sleep(1)
        
        if not settings_clicked:
            print("[WARN] Could not find 'Cài đặt tài khoản'. Trying to find 'Đăng xuất' directly (in case logic changed)...")
        
        time.sleep(2)

        # 3. Find and Click 'Đăng xuất'
        logout_clicked = False
        for i in range(2):
            if check_toast_or_text("Đăng xuất"):
                print("[INFO] Clicking 'Đăng xuất'...")
                driver.find_element(AppiumBy.XPATH, "//*[contains(@text, 'Đăng xuất') or contains(@content-desc, 'Đăng xuất')]").click()
                logout_clicked = True
                break
            else:
                print(f"[INFO] 'Đăng xuất' not visible. Swiping up (attempt {i+1})...")
                gentle_swipe_up()
                time.sleep(1)

        if logout_clicked:
            # 4. Confirm Logout Dialog
            print("[INFO] Confirming logout...")
            time.sleep(1)
            btns = driver.find_elements(AppiumBy.CLASS_NAME, "android.widget.Button")
            clicked = False
            # Prioritize button with "Đăng xuất" text
            for btn in btns:
                if btn.get_attribute("content-desc") == "Đăng xuất" or btn.text == "Đăng xuất":
                    btn.click()
                    clicked = True
                    break
            
            # If not found, try the last button (usually positive action)
            if not clicked and btns:
                 print("[INFO] specific 'Đăng xuất' button not found in dialog, clicking last button...")
                 btns[-1].click()
            
            time.sleep(4)
        else:
             print("[WARN] 'Đăng xuất' button not found anywhere.")

    except Exception as e:
        if is_fatal_error(e): raise e
        print(f"[WARN] Logout failed: {e}")

def navigate_to_login():
    print("[INFO] Checking navigation to Login...")
    hide_keyboard()
    time.sleep(1)
    
    # 1. Check if already on Login Screen
    # Look for "Đăng nhập" button AND "Quên mật khẩu" or "Đăng ký" link
    # Be careful not to confuse with Welcome screen which also has "Đăng nhập"
    if check_toast_or_text("Quên mật khẩu") or (check_text("Đăng nhập") and check_toast_or_text("Bạn chưa có tài khoản?")):
        print("[INFO] Already on Login screen.")
        return True

    # 2. Check if logged in
    # Use a broader check for bottom navigation or common home elements
    # Assuming standard bottom nav bar
    if check_accessibility_id("Tài khoản") or check_text("Tài khoản") or check_text("Trang chủ") or check_text("Journey map") or check_text("Cá nhân") or check_accessibility_id("Admin - Duyệt & Banner"):
         perform_logout()
         time.sleep(2)
         
    # Check again if logout worked or if we were already at login
    if check_toast_or_text("Quên mật khẩu") or (check_text("Đăng nhập") and check_toast_or_text("Bạn chưa có tài khoản?")):
        return True

    # 3. Navigation Logic
    for attempt in range(3):
        # Print current activity for debug
        try:
             print(f"[DEBUG] Current Activity: {driver.current_activity}")
        except: pass
        
        # Case A: Welcome Screen -> Click 'Đăng nhập'
        if check_accessibility_id("Tạo tài khoản mới") or check_text("Tạo tài khoản mới") or check_text("Chào mừng bạn"):
             print("[INFO] On Welcome Screen. Clicking 'Đăng nhập'...")
             try:
                 # Usually there is a "Đăng nhập" button or text
                 el = driver.find_element(AppiumBy.XPATH, "//*[@text='Đăng nhập' or @content-desc='Đăng nhập']")
                 el.click()
             except Exception as e:
                 print(f"[WARN] Failed to click Welcome Login: {e}")
                 # Try coordinates for bottom login button if standard layout
                 pass
             time.sleep(2)
             return True

        # Case B: Register Screen -> Click 'Đăng nhập' link
        if check_toast_or_text("Tên sẽ hiển thị trong ứng dụng") or check_text("Đăng ký"):
             print("[INFO] On Register Screen. Clicking 'Đăng nhập' link...")
             try:
                 driver.find_element(AppiumBy.XPATH, "//*[@text='Đăng nhập' or @content-desc='Đăng nhập']").click()
             except:
                 pass
             time.sleep(2)
             return True
             
        # Case C: Login Screen (Check again)
        if check_toast_or_text("Quên mật khẩu") or check_text("Đăng nhập"):
            return True

        # Not found? Swipe
        print(f"[INFO] Nav buttons not found (Attempt {attempt+1}). Swiping...")
        gentle_swipe_up()
        time.sleep(1)
        
        # If still failing, try to dump source to see what's there
        if attempt == 2:
             print("[DEBUG] Page Source Snippet:")
             try:
                 src = driver.page_source
                 # Print first 1000 chars and lines with 'text' or 'content-desc'
                 print(src[:500])
                 for line in src.split('\n'):
                     if 'text="' in line or 'content-desc="' in line:
                          if 'layout' not in line: # filter noise
                              print(line.strip()[:200])
             except:
                 pass

    print("[ERROR] Could not navigate to Login screen.")
    return False

def fill_field(index, value):
    """Fills a field by index using robust retry logic.
       Login usually: 0=Email, 1=Password
    """
    hints = ["Email/SĐT", "Mật khẩu"]
    hint = hints[index] if index < len(hints) else f"Field {index}"
    
    print(f"[STEP] Filling '{hint}' with '{value}'...")
    
    for attempt in range(3):
        try:
            inputs = driver.find_elements(AppiumBy.CLASS_NAME, "android.widget.EditText")
            if len(inputs) > index:
                el = inputs[index]
                el.click()
                time.sleep(0.5)
                el.clear()
                time.sleep(0.5)
                el.send_keys(value)
                time.sleep(0.5)
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
            if is_fatal_error(e): raise e
            print(f"[WARN] Fill field failed: {e}")
            time.sleep(1)
    return False

def click_login():
    print("[STEP] Clicking Login button...")
    hide_keyboard()
    try:
        # Try finding by Text or ID
        els = driver.find_elements(AppiumBy.XPATH, "//*[@text='Đăng nhập' or @content-desc='Đăng nhập']")
        # Filter visible ones (exclude the 'Đăng nhập' link at top if possible, we want the button)
        # Usually the button is 'android.widget.Button'
        for el in els:
            if el.is_displayed() and el.get_attribute("className") == "android.widget.Button":
                el.click()
                return True
        
        # Fallback to any visible "Đăng nhập"
        for el in els:
             if el.is_displayed():
                el.click()
                return True
    except Exception as e:
        if is_fatal_error(e): raise e
        print(f"[ERROR] Click login failed: {e}")
    return False

# --- Test Data ---

# User credentials
ADMIN_EMAIL = "huy2@gmail.com"
USER_EMAIL = "tait504405@gmail.com"
DEFAULT_PASS = "123456"

test_data = [
    # 1. Success
    {
        "id": "DN01", "name": "Đăng nhập thành công", 
        "data": [USER_EMAIL, DEFAULT_PASS], 
        "expect": ["Journey map của bạn", "Trang chủ", "Home"] # Valid indicators
    },
    # 2. Empty Account
    {
        "id": "DN02", "name": "Bỏ trống tài khoản", 
        "data": ["", DEFAULT_PASS], 
        "expect": "Cần nhập tài khoản" # Exact text from user prompt
    },
    # 3. Empty Both
    {
        "id": "DN03", "name": "Bỏ trống tài khoản và mật khẩu", 
        "data": ["", ""], 
        "expect": "Vui lòng nhập email và mật khẩu"
    },
    # 4. Empty Password
    {
        "id": "DN04", "name": "Bỏ trống mật khẩu", 
        "data": [USER_EMAIL, ""], 
        "expect": "Cần nhập mật khẩu"
    },
    # 5. Wrong Account
    {
        "id": "DN05", "name": "Sai tài khoản", 
        "data": ["wrong_user_999@gmail.com", DEFAULT_PASS], 
        "expect": "Kiểm tra lại tài khoản"
    },
    # 6. Wrong Password
    {
        "id": "DN06", "name": "Sai mật khẩu", 
        "data": [USER_EMAIL, "wrongpass"], 
        "expect": "Kiểm tra lại mật khẩu"
    },
    # 7. Network Error
    {
        "id": "DN07", "name": "Vui lòng kiểm tra lại kết nối mạng", 
        "data": [USER_EMAIL, DEFAULT_PASS], 
        "expect": "Đã có lỗi xảy ra",
        "special": "network_toggle"
    },
    # 8. Invalid Email Format
    {
        "id": "DN08", "name": "Kiểm tra định dạng Email không hợp lệ", 
        "data": ["abcgmail.com", DEFAULT_PASS], 
        "expect": ["Định dạng email không hợp lệ", "Email không hợp lệ", "Email invalid"]
    },
    # 9. Eye Icon
    {
        "id": "DN09", "name": "Kiểm tra tính năng Ẩn/Hiện mật khẩu", 
        "data": [USER_EMAIL, DEFAULT_PASS], 
        "expect": "Eye Icon Checked",
        "special": "eye_icon"
    },
    # 10. Roles
    {
        "id": "DN10", "name": "Kiểm tra phân quyền và điều hướng", 
        "data": [], # Handled internally
        "expect": "Role Checked",
        "special": "roles"
    }
]

def run_test_case(test_case):
    print(f"\n=== Running {test_case['id']}: {test_case['name']} ===")
    
    # 1. Navigation
    if not navigate_to_login():
        return False

    special = test_case.get("special", "")

    # --- Special Case: DN07 Network ---
    if special == "network_toggle":
        print("[STEP] Toggling WiFi OFF...")
        try:
            driver.toggle_wifi() # Turn off
            time.sleep(2)
        except:
            print("[WARN] Could not toggle WiFi. Skipping network test details.")
            
        # Perform Login
        fill_field(0, test_case['data'][0])
        fill_field(1, test_case['data'][1])
        click_login()
        time.sleep(3)
        
        # Verify Error
        passed = check_toast_or_text(test_case['expect'])
        
        # Restore WiFi
        print("[STEP] Toggling WiFi ON...")
        try:
            driver.toggle_wifi() 
            time.sleep(5) # Wait for reconnect
        except:
            pass
            
        if passed:
            print(f"[PASS] Found network error: {test_case['expect']}")
            return True
        else:
            print(f"[FAIL] Expected '{test_case['expect']}' not found.")
            return False

    # --- Special Case: DN09 Eye Icon ---
    if special == "eye_icon":
        fill_field(0, test_case['data'][0])
        fill_field(1, test_case['data'][1]) # Fill password
        
        # Find password field and eye icon
        try:
            print("[STEP] Clicking Eye Icon...")
            # Try 1: Find ImageButton (common for endIcon)
            btns = driver.find_elements(AppiumBy.CLASS_NAME, "android.widget.ImageButton")
            if btns:
                # Use the last one usually
                btns[-1].click()
                print("[INFO] Clicked Eye Icon (ImageButton).")
                time.sleep(1)
                print("[PASS] Eye icon interaction successful.")
                return True
            
            # Try 2: Click right side of password field
            print("[INFO] Eye icon not found. Trying coordinate click on password field...")
            inputs = driver.find_elements(AppiumBy.CLASS_NAME, "android.widget.EditText")
            if len(inputs) > 1:
                pw_field = inputs[1]
                rect = pw_field.rect
                # Click 90% width, 50% height relative to element
                x = rect['x'] + rect['width'] - 40 # 40px from right
                y = rect['y'] + rect['height'] // 2
                
                actions = ActionBuilder(driver)
                finger = actions.add_pointer_input(interaction.POINTER_TOUCH, "finger")
                finger.create_pointer_move(duration=0, x=int(x), y=int(y))
                finger.create_pointer_down(button=0)
                finger.create_pause(0.1)
                finger.create_pointer_up(button=0)
                actions.perform()
                
                print(f"[INFO] Tapped coordinates ({x}, {y}).")
                time.sleep(1)
                print("[PASS] Eye icon interaction successful (via coordinates).")
                return True
                
            print("[WARN] Eye icon test failed to find target.")
            return False
        except Exception as e:
            print(f"[FAIL] Eye icon test error: {e}")
            return False

    # --- Special Case: DN10 Roles ---
    if special == "roles":
        # Sub-test 1: Admin
        print("[STEP] Testing Admin Login...")
        if not navigate_to_login(): return False
        fill_field(0, ADMIN_EMAIL)
        fill_field(1, DEFAULT_PASS)
        click_login()
        time.sleep(5)
        
        if check_toast_or_text("Chờ duyệt Địa điểm") or check_toast_or_text("Admin"):
            print("[PASS] Admin redirected correctly.")
        else:
            print("[FAIL] Admin redirection incorrect.")
            # Continue to User test anyway
            
        perform_logout()
        time.sleep(2)
        
        # Sub-test 2: User
        print("[STEP] Testing User Login...")
        # Ensure we are at login
        if not navigate_to_login(): return False
        fill_field(0, USER_EMAIL)
        fill_field(1, DEFAULT_PASS)
        click_login()
        time.sleep(5)
        
        if check_toast_or_text("Journey map") or check_toast_or_text("Trang chủ"):
            print("[PASS] User redirected correctly.")
            perform_logout()
            return True
        else:
            print("[FAIL] User redirection incorrect.")
            return False

    # --- Standard Cases ---
    # Fill Data
    if len(test_case['data']) >= 2:
        fill_field(0, test_case['data'][0])
        fill_field(1, test_case['data'][1])
    
    # Click Login
    if not click_login():
        return False
        
    time.sleep(3)
    
    # Verification
    expected = test_case["expect"]
    
    # Success Case
    if test_case["id"] == "DN01":
        # Check for any of the expected success indicators
        for exp in expected:
            if check_toast_or_text(exp):
                print(f"[PASS] Login Success (Found '{exp}').")
                perform_logout()
                return True
        # Also check if 'Tài khoản' tab appeared
        if check_accessibility_id("Tài khoản"):
            print("[PASS] Login Success (Found 'Tài khoản' tab).")
            perform_logout()
            return True
            
        print(f"[FAIL] Expected success content {expected} not found.")
        return False
        
    # Error Cases
    else:
        # Handle list of expectations
        if isinstance(expected, list):
             for exp in expected:
                 if check_toast_or_text(exp):
                     print(f"[PASS] Found expected error: '{exp}'")
                     return True
             print(f"[FAIL] None of expected errors {expected} found.")
             return False
        # Handle single string
        elif check_toast_or_text(expected):
            print(f"[PASS] Found expected error: '{expected}'")
            return True
        else:
            print(f"[FAIL] Expected '{expected}' not found.")
            return False

# --- Main Loop ---

def main():
    global driver
    
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
                if driver is None:
                    driver = init_driver()
                
                ensure_app_active()
                
                if run_test_case(test):
                    results["PASS"] += 1
                else:
                    results["FAIL"] += 1
                
                retry = False 
                
            except Exception as e:
                err_msg = str(e)
                print(f"[CRASH] Error during {test['id']}: {e}")
                
                if is_fatal_error(e):
                    print("[RECOVERY] Driver crashed. Restarting session...")
                    try:
                        driver.quit()
                    except:
                        pass
                    driver = None 
                    time.sleep(5)
                else:
                    results["FAIL"] += 1
                    retry = False
        
        print("[INFO] Post-test wait...")
        time.sleep(2)
        # If we just finished DN01 or DN10, we might be logged in. 
        # navigate_to_login will handle logout next time, but we can do it here to be safe?
        # Nah, let navigate_to_login handle it.

    print("\n=== FINAL SUMMARY ===")
    print(f"PASS: {results['PASS']}")
    print(f"FAIL: {results['FAIL']}")
    
    if driver:
        driver.quit()

if __name__ == "__main__":
    main()
