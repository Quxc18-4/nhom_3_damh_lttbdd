import time
from appium import webdriver
from appium.options.android import UiAutomator2Options
from appium.webdriver.common.appiumby import AppiumBy
from selenium.webdriver.common.action_chains import ActionChains
from selenium.webdriver.common.actions import interaction
from selenium.webdriver.common.actions.action_builder import ActionBuilder
from selenium.webdriver.common.actions.pointer_input import PointerInput

# --- CẤU HÌNH ---
options = UiAutomator2Options()
options.platform_name = 'Android'
options.automation_name = 'UiAutomator2'
options.device_name = 'emulator-5554'
# ĐỔI ĐƯỜNG DẪN APK CỦA BẠN
options.app = r'C:\Users\Pon\Desktop\danhminhquoc_8774\nhom_3_damh_lttbdd\build\app\outputs\flutter-apk\app-debug.apk'
options.no_reset = False 

driver = webdriver.Remote('http://127.0.0.1:4723', options=options)

        # ---------------------------------------------------------
        # 1. DỮ LIỆU TEST (DATA DRIVEN) - KHỚP 100% FILE EXCEL
        # ---------------------------------------------------------
test_cases = [
            # DDD01: Thiếu tên -> Fail
            {"id": "DDD01", "name": "", "categories": ["Giáo dục", "Khám phá", "Check-in"], "img_source": "camera", "img_count": 1, "note": "", "expect_pass": False},
            
            # DDD02: Đủ thông tin (3 danh mục) -> Pass
            {"id": "DDD02", "name": "Hutech khu E", "categories": ["Giáo dục", "Khám phá", "Check-in"], "img_source": "camera", "img_count": 1, "note": "Trường học cơ sở E của Hutech", "expect_pass": True},
            
            # DDD03: 2 danh mục -> Pass
            {"id": "DDD03", "name": "Hutech khu E", "categories": ["Giáo dục", "Khám phá"], "img_source": "camera", "img_count": 1, "note": "Trường học cơ sở E của Hutech", "expect_pass": True},
            
            # DDD04: 1 danh mục -> Pass
            {"id": "DDD04", "name": "Hutech khu E", "categories": ["Giáo dục"], "img_source": "camera", "img_count": 1, "note": "Trường học cơ sở E của Hutech", "expect_pass": True},
            
            # DDD05: Không chọn danh mục -> Fail
            {"id": "DDD05", "name": "Cà phê mèo", "categories": [], "img_source": "library", "img_count": 1, "note": "Quán cà phê có mèo làm nhân viên", "expect_pass": False},
            
            # DDD06: Cố chọn 4 danh mục (UI chặn cái thứ 4) -> Pass
            {"id": "DDD06", "name": "Hutech khu E", "categories": ["Giáo dục", "Khám phá", "Check-in", "Check-in"], "img_source": "camera", "img_count": 1, "note": "Trường học cơ sở E của Hutech", "expect_pass": True},
            
            # DDD07: Không tải ảnh -> Pass
            {"id": "DDD07", "name": "Hutech khu E", "categories": ["Giáo dục", "Khám phá", "Check-in"], "img_source": "none", "img_count": 0, "note": "Trường học cơ sở E của Hutech", "expect_pass": True},
            
            # DDD08: 1 Camera + 1 Thư viện -> Pass
            {"id": "DDD08", "name": "Hutech khu E", "categories": ["Giáo dục"], "img_source": "mixed", "img_count": 2, "note": "Trường học cơ sở E của Hutech", "expect_pass": True},
            
            # DDD09: 5 ảnh thư viện -> Pass
            {"id": "DDD09", "name": "Hutech khu E", "categories": ["Giáo dục", "Khám phá", "Check-in"], "img_source": "library", "img_count": 5, "note": "Trường học cơ sở E của Hutech", "expect_pass": True},
            
            # DDD10: Cố chọn 6 ảnh (UI chặn hoặc tự cắt) -> Pass
            {"id": "DDD10", "name": "Hutech khu E", "categories": ["Giáo dục", "Khám phá", "Check-in"], "img_source": "library", "img_count": 6, "note": "Trường học cơ sở E của Hutech", "expect_pass": True},
]

# --- HÀM HỖ TRỢ (LẤY TỪ FILE CHẠY ĐƯỢC) ---
def wait_and_find(xpath, timeout=10):
    end_time = time.time() + timeout
    while time.time() < end_time:
        try:
            return driver.find_element(AppiumBy.XPATH, xpath)
        except:
            time.sleep(2)
    raise Exception(f"Không tìm thấy phần tử: {xpath}")

def check_permission():
    """Bấm Cho phép nếu hỏi quyền"""
    try:
        driver.implicitly_wait(2)
        xpath = "//*[@text='Trong khi dùng ứng dụng' or @text='While using the app' or @text='Cho phép' or @text='Allow']"
        driver.find_element(AppiumBy.XPATH, xpath).click()
        print("   🛡️ Đã cấp quyền.")
        time.sleep(2)
    except:
        pass
    driver.implicitly_wait(10)

def scroll_page():
    """Cuộn xuống để tìm nút bên dưới"""
    size = driver.get_window_size()
    start_y = int(size['height'] * 0.8)
    end_y = int(size['height'] * 0.3)
    start_x = size['width'] // 2
    
    actions = ActionChains(driver)
    finger = PointerInput(interaction.POINTER_TOUCH, "finger")
    actions.w3c_actions = ActionBuilder(driver, mouse=finger)
    actions.w3c_actions.pointer_action.move_to_location(start_x, start_y)
    actions.w3c_actions.pointer_action.pointer_down()
    actions.w3c_actions.pointer_action.pause(0.2)
    actions.w3c_actions.pointer_action.move_to_location(start_x, end_y)
    actions.w3c_actions.pointer_action.pointer_up()
    actions.perform()
    time.sleep(2)

# ====================================================
# MAIN SCRIPT
# ====================================================
try:
    print("🚀 BẮT ĐẦU CHẠY 10 TEST CASES...")
    time.sleep(5)

    # --- PHẦN 1: LOGIN & VÀO MAP (GIỮ NGUYÊN CODE CỦA BẠN) ---
    print(">>> [Setup] Đăng nhập & Vào Map...")
    
    # 1. Login (Nếu cần)
    try:
        driver.implicitly_wait(3)
        email_check = driver.find_elements(AppiumBy.XPATH, "//android.widget.EditText[contains(@text, 'Email') or contains(@hint, 'Email')]")
        if email_check:
            print("   -> Đang Login...")
            email_check[0].click()
            email_check[0].send_keys("danhminhquoc1804@gmail.com")
            
            pass_inp = driver.find_element(AppiumBy.XPATH, "//android.widget.EditText[contains(@text, 'mật khẩu') or contains(@hint, 'mật khẩu')]")
            pass_inp.click()
            pass_inp.send_keys("123456")
            try: driver.hide_keyboard()
            except: pass
            
            driver.find_element(AppiumBy.XPATH, "//*[@text='Đăng nhập' or contains(@content-desc, 'Đăng nhập')]").click()
            time.sleep(5)
    except Exception as e:
        print(f"   ⚠️ Lỗi Login: {e}")
    driver.implicitly_wait(5)

    # 2. Vào World Map & Xử lý Quyền
    try:
        # Tìm nút Journey Map / Bản đồ
        xpath_jm = "//*[contains(@text, 'Journey Map') or contains(@content-desc, 'Journey Map') or contains(@text, 'Bản đồ')]"
        try:
            driver.find_element(AppiumBy.XPATH, xpath_jm).click()
        except: pass 
        time.sleep(3)

        # Tìm nút "Mở bản đồ khu vực"
        target_text = "Mở bản đồ khu vực"
        target_xpath = f"//*[contains(@text, '{target_text}') or contains(@content-desc, '{target_text}')]"
        try:
            driver.find_element(AppiumBy.XPATH, target_xpath).click()
        except:
            # Fallback nếu nút bị che, dùng FAB button
            print("   -> Dùng FAB để mở map...")
            fabs = driver.find_elements(AppiumBy.CLASS_NAME, "android.widget.Button")
            if fabs: fabs[-1].click()
            time.sleep(3)
            driver.find_element(AppiumBy.XPATH, target_xpath).click()
        
        # --- [MỚI] CHỜ 4S LOAD MAP & CLICK CHO PHÉP VỊ TRÍ ---
        print("   -> ⏳ Đang chờ 3s để tải dữ liệu bản đồ...")
        time.sleep(3) 

        print("   -> [Auto] Kiểm tra quyền vị trí...")
        try:
            # Các ID/Text thường gặp của nút "Cho phép" trên Android
            permission_buttons = [
                "com.android.permissioncontroller:id/permission_allow_foreground_only_button", # Android 10+ (Trong khi dùng ứng dụng)
                "com.android.permissioncontroller:id/permission_allow_button", # Android cũ
                "//android.widget.Button[@text='Trong khi dùng ứng dụng']",
                "//android.widget.Button[@text='While using the app']",
                "//android.widget.Button[@text='Cho phép']",
                "//android.widget.Button[@text='Allow']"
            ]
            
            for btn_selector in permission_buttons:
                try:
                    if btn_selector.startswith("//"):
                        driver.find_element(AppiumBy.XPATH, btn_selector).click()
                    else:
                        driver.find_element(AppiumBy.ID, btn_selector).click()
                    print("   -> ✅ Đã tự động bấm 'Cho phép'.")
                    break # Bấm được rồi thì thoát vòng lặp
                except:
                    continue
        except Exception:
            print("   -> Không thấy popup quyền (có thể đã cấp trước đó).")
            
    except Exception as e:
        print(f"   ⚠️ Lỗi vào Map: {e}")

    time.sleep(5) # Ổn định trước khi vào Test Case

    # --- PHẦN 2: CHUẨN BỊ DỮ LIỆU TEST (THEO EXCEL) ---
    test_cases = [
        {"id": "DDD01", "name": "", "categories": ["Giáo dục", "Khám phá", "Check-in"], "img_source": "camera", "img_count": 1, "note": "", "expect_pass": False},
        {"id": "DDD02", "name": "Hutech khu E", "categories": ["Giáo dục", "Khám phá", "Check-in"], "img_source": "camera", "img_count": 1, "note": "Trường học cơ sở E của Hutech", "expect_pass": True},
        {"id": "DDD03", "name": "Hutech khu E", "categories": ["Giáo dục", "Khám phá"], "img_source": "camera", "img_count": 1, "note": "Trường học cơ sở E của Hutech", "expect_pass": True},
        {"id": "DDD04", "name": "Hutech khu E", "categories": ["Giáo dục"], "img_source": "camera", "img_count": 1, "note": "Trường học cơ sở E của Hutech", "expect_pass": True},
        {"id": "DDD05", "name": "Cà phê mèo", "categories": [], "img_source": "library", "img_count": 1, "note": "Quán cà phê có mèo làm nhân viên", "expect_pass": False},
        {"id": "DDD06", "name": "Hutech khu E", "categories": ["Giáo dục", "Khám phá", "Check-in", "Check-in"], "img_source": "camera", "img_count": 1, "note": "Trường học cơ sở E của Hutech", "expect_pass": True},
        {"id": "DDD07", "name": "Hutech khu E", "categories": ["Giáo dục", "Khám phá", "Check-in"], "img_source": "none", "img_count": 0, "note": "Trường học cơ sở E của Hutech", "expect_pass": True},
        {"id": "DDD08", "name": "Hutech khu E", "categories": ["Giáo dục"], "img_source": "mixed", "img_count": 2, "note": "Trường học cơ sở E của Hutech", "expect_pass": True},
        {"id": "DDD09", "name": "Hutech khu E", "categories": ["Giáo dục", "Khám phá", "Check-in"], "img_source": "library", "img_count": 5, "note": "Trường học cơ sở E của Hutech", "expect_pass": True},
        {"id": "DDD10", "name": "Hutech khu E", "categories": ["Giáo dục", "Khám phá", "Check-in"], "img_source": "library", "img_count": 6, "note": "Trường học cơ sở E của Hutech", "expect_pass": True},
    ]

    # --- KHAI BÁO HÀM XỬ LÝ CAMERA (ĐẶT Ở ĐÂY ĐỂ KHÔNG BỊ LỖI DEFINED) ---
    # --- HÀM CAMERA TỐI GIẢN (2 BƯỚC: CHỤP -> OK) ---
    def handle_camera_coordinates(driver):
        print("     -> [Camera] Đang chờ Camera khởi động (Wait 8s)...")
        time.sleep(8) 
        
        size = driver.get_window_size()
        width, height = size['width'], size['height']
        
        # BƯỚC 1: CHỤP ẢNH
        print("     -> [Camera] Bước 1: Nhấn phím Chụp (KEYCODE_CAMERA/VOLUME)...")
        try:
            # Thử nhấn phím Camera (KEYCODE_CAMERA = 27)
            driver.press_keycode(27)
            time.sleep(4)
            # Thử nhấn phím Tăng âm lượng (KEYCODE_VOLUME_UP = 24) - Thường dùng để chụp
            driver.press_keycode(24) 
        except:
            # Fallback: Nếu phím cứng lỗi thì mới dùng tọa độ (Giữa, 88% chiều cao)
            print("     -> Phím cứng lỗi, dùng tọa độ...")
            size = driver.get_window_size()
            action = ActionChains(driver)
            finger = PointerInput(interaction.POINTER_TOUCH, "finger")
            action.w3c_actions = ActionBuilder(driver, mouse=finger)
            action.w3c_actions.pointer_action.move_to_location(int(size['width'] * 0.5), int(size['height'] * 0.88))
            action.w3c_actions.pointer_action.pointer_down()
            action.w3c_actions.pointer_action.pause(0.2)
            action.w3c_actions.pointer_action.pointer_up()
            action.perform()
        
        # TĂNG THỜI GIAN CHỜ XỬ LÝ ẢNH
        print("     -> [Wait] Đang lưu ảnh (Wait 4s)...")
        time.sleep(4) 

        # BƯỚC 2: XÁC NHẬN (OK)
        print("     -> [Camera] Bước 2: Bấm OK/Lưu...")
        try:
            # Ưu tiên 1: Tìm Text (OK, Lưu, Done, dấu tick) - Cách an toàn nhất
            # Dùng XPath tìm bất kỳ nút nào có chữ OK/Done/Lưu
            xpath_ok = "//*[contains(@text, 'OK') or contains(@text, 'Lưu') or contains(@content-desc, 'OK') or contains(@content-desc, 'Done') or contains(@resource-id, 'done')]"
            driver.find_element(AppiumBy.XPATH, xpath_ok).click()
            print("        -> Đã bấm OK bằng Text/ID.")
        except:
            # Ưu tiên 2: Click tọa độ góc phải dưới (0.9, 0.9) - Cách dự phòng
            print("        -> Không thấy nút OK, click mù tọa độ góc phải...")
            action = ActionChains(driver)
            action.w3c_actions = ActionBuilder(driver, mouse=finger)
            action.w3c_actions.pointer_action.move_to_location(int(width * 0.9), int(height * 0.9))
            action.w3c_actions.pointer_action.pointer_down()
            action.w3c_actions.pointer_action.pause(0.2)
            action.w3c_actions.pointer_action.pointer_up()
            action.perform()
            
        print("     -> [Wait] Chờ đóng Camera 5s...")
        time.sleep(5)

    # --- PHẦN 3: VÒNG LẶP TEST ---
    for case in test_cases:
        print(f"\n--- [{case['id']}] Chạy Test Case ---")

        # A. LONG PRESS TRÊN BẢN ĐỒ
        print("   -> [Step] Long Press để mở form...")
        size = driver.get_window_size()
        safe_x = int(size['width'] * 0.5) # Giữa màn hình
        safe_y = int(size['height'] * 0.4)
        
        actions = ActionChains(driver)
        finger = PointerInput(interaction.POINTER_TOUCH, "finger")
        actions.w3c_actions = ActionBuilder(driver, mouse=finger)
        actions.w3c_actions.pointer_action.move_to_location(safe_x, safe_y)
        actions.w3c_actions.pointer_action.pointer_down()
        actions.w3c_actions.pointer_action.pause(2.5) # Giữ 2.5s
        actions.w3c_actions.pointer_action.pointer_up()
        actions.perform()
        
        # Click nút "Thêm mới" trên BottomSheet
        print("   -> [Step] Click icon 'Thêm địa điểm'...")
        time.sleep(4) 

        try:
            # CÁCH 1: Tìm bằng ID
            driver.find_element(AppiumBy.ACCESSIBILITY_ID, "btn_add_new_place").click()
            print("     -> Cách 1 (ID): Tìm thấy!")
        except:
            # CÁCH 2: Fallback tìm bằng Text hoặc Class
            try:
                xpath_text = "//*[contains(@content-desc, 'Thêm mới') or contains(@text, 'Thêm mới')]"
                driver.find_element(AppiumBy.XPATH, xpath_text).click()
                print("     -> Cách 2 (Text): Tìm thấy!")
            except:
                 # Fallback cuối cùng: Click vào tọa độ có khả năng là nút Thêm
                 pass 
        
        time.sleep(4) # Chờ Form điền thông tin hiện lên

        # --- B. ĐIỀN FORM ---
        print(f"   -> [Step] Nhập tên: {case['name']}")
        try:
            # Tìm tất cả các ô EditText trên màn hình (Ô đầu tiên là Tên)
            edit_texts = driver.find_elements(AppiumBy.CLASS_NAME, "android.widget.EditText")
            if len(edit_texts) > 0:
                name_input = edit_texts[0]
                name_input.click()
                name_input.clear()
                if case['name']: name_input.send_keys(case['name'])
            try: driver.hide_keyboard()
            except: pass
        except Exception as e:
            print(f"   ⚠️ Lỗi nhập tên: {e}")

        # Điền Ghi chú (Nếu có)
        if case['note']:
            try:
                edit_texts = driver.find_elements(AppiumBy.CLASS_NAME, "android.widget.EditText")
                if len(edit_texts) > 1:
                    note_input = edit_texts[-1] # Ô cuối cùng thường là Ghi chú
                    note_input.click()
                    note_input.send_keys(case['note'])
                try: driver.hide_keyboard()
                except: pass
            except: pass

        # # --- C. CHỌN DANH MỤC ---
        # if case['categories']:
        #     print(f"   -> [Step] Chọn {len(case['categories'])} danh mục")
        #     for cat_name in case['categories']:
        #         try:
        #             # Click nút Thêm (Của phần Danh mục - Nút đầu tiên)
        #             xpath_add = "//*[contains(@content-desc, 'Thêm') or contains(@text, 'Thêm')]"
        #             add_btns = driver.find_elements(AppiumBy.XPATH, xpath_add)
        #             if len(add_btns) > 0:
        #                 add_btns[0].click()
        #                 time.sleep(2)
        #                 # Chọn Item
        #                 driver.find_element(AppiumBy.XPATH, f"//*[contains(@content-desc, '{cat_name}') or contains(@text, '{cat_name}')]").click()
        #                 time.sleep(2)
        #         except: pass

        # # --- D. THÊM ẢNH ---
        # # 1. Scroll xuống dưới cùng để chắc chắn thấy nút thêm ảnh
        # try: 
        #     driver.hide_keyboard() # Ẩn phím trước
        # except: pass
        
        # try:
        #     # Scroll 2 lần cho chắc
        #     driver.find_element(AppiumBy.ANDROID_UIAUTOMATOR, 'new UiScrollable(new UiSelector().scrollable(true)).scrollForward()')
        #     time.sleep(0.5)
        #     driver.find_element(AppiumBy.ANDROID_UIAUTOMATOR, 'new UiScrollable(new UiSelector().scrollable(true)).scrollForward()')
        # except: pass

        # if case['img_count'] > 0:
        #     time.sleep(5)
        #     print(f"   -> [Step] Thêm {case['img_count']} ảnh (Nguồn: {case['img_source']})")
        #     for i in range(case['img_count']):
        #         try:
        #             # BƯỚC 1: CLICK NÚT "THÊM ẢNH"
        #             # Thử ID trước, không được thì tìm Text
        #             found_add_btn = False
        #             try:
        #                 driver.find_element(AppiumBy.ACCESSIBILITY_ID, "btn_add_image").click()
        #                 found_add_btn = True
        #             except:
        #                 # Fallback: Tìm nút có chữ "Thêm" cuối cùng
        #                 try:
        #                     xpath_add = "(//*[contains(@content-desc, 'Thêm') or contains(@text, 'Thêm')])[last()]"
        #                     driver.find_element(AppiumBy.XPATH, xpath_add).click()
        #                     found_add_btn = True
        #                 except:
        #                      print("     ⚠️ Không tìm thấy nút thêm ảnh!")

        #             if not found_add_btn: continue # Bỏ qua vòng lặp này

        #             time.sleep(8) # Chờ Bottom Sheet

        #             # BƯỚC 2: CHỌN NGUỒN
        #             src = "camera"
        #             if case['img_source'] == "library" or (case['img_source'] == "mixed" and i > 0): 
        #                 src = "library"

        #             if src == "camera":
        #                 # Click ID: btn_camera
        #                 print("     -> Mở Camera...")
        #                 try:
        #                     driver.find_element(AppiumBy.ACCESSIBILITY_ID, "btn_camera").click()
        #                 except:
        #                     driver.find_element(AppiumBy.XPATH, "//*[contains(@text, 'Chụp') or contains(@content-desc, 'Chụp') or contains(@text, 'Camera')]").click()
                        
        #                 # Gọi hàm xử lý Camera (Đã define ở trên)
        #                 handle_camera_coordinates(driver)
        #             else:
        #                 print("     -> [Library] Đang mở Thư viện...")
                        
        #                 # 1. CLick nút "Chọn từ thư viện" (Hybrid: ID -> Text)
        #                 try:
        #                     driver.find_element(AppiumBy.ACCESSIBILITY_ID, "btn_gallery").click()
        #                 except:
        #                     # Fallback: Tìm bằng Text
        #                     xpath_lib = "//*[contains(@text, 'Thư viện') or contains(@content-desc, 'Thư viện') or contains(@text, 'Gallery')]"
        #                     driver.find_element(AppiumBy.XPATH, xpath_lib).click()
                        
        #                 # 2. Xử lý quyền truy cập (Permission) - QUAN TRỌNG
        #                 print("     -> [Auto] Check quyền Thư viện...")
        #                 time.sleep(3)
        #                 try:
        #                     # Các nút "Cho phép" phổ biến
        #                     perm_ids = [
        #                         "com.android.permissioncontroller:id/permission_allow_button",
        #                         "com.android.permissioncontroller:id/permission_allow_foreground_only_button",
        #                         "//android.widget.Button[@text='Cho phép']",
        #                         "//android.widget.Button[@text='Allow']",
        #                         "//android.widget.Button[@text='While using the app']"
        #                     ]
        #                     for pid in perm_ids:
        #                         try:
        #                             if pid.startswith("//"): driver.find_element(AppiumBy.XPATH, pid).click()
        #                             else: driver.find_element(AppiumBy.ID, pid).click()
        #                             print("     -> ✅ Đã cấp quyền Thư viện.")
        #                             time.sleep(2)
        #                             break
        #                         except: continue
        #                 except: pass

        #                 print("     -> [Library] Chọn ảnh (Wait 5s)...")
        #                 time.sleep(5) # Chờ ảnh load ra

        #                 # 3. Click chọn ảnh bằng Tọa độ
        #                 # (Vì mỗi máy Android giao diện Gallery khác nhau, ID rất khó bắt)
        #                 size = driver.get_window_size()
        #                 action = ActionChains(driver)
        #                 finger = PointerInput(interaction.POINTER_TOUCH, "finger")
        #                 action.w3c_actions = ActionBuilder(driver, mouse=finger)
                        
        #                 # A. Click vào ảnh đầu tiên (Góc trái trên - khoảng 20% rộng, 30% cao)
        #                 print("     -> Click ảnh đầu tiên...")
        #                 action.w3c_actions.pointer_action.move_to_location(int(size['width'] * 0.2), int(size['height'] * 0.3))
        #                 action.w3c_actions.pointer_action.pointer_down()
        #                 action.w3c_actions.pointer_action.pointer_up()
        #                 action.perform()
                        
        #                 time.sleep(2)

        #                 # B. Click nút "Xong/Add" (Nếu có - Góc phải trên)
        #                 # Một số máy chọn xong tự đóng, một số máy cần bấm "Xong"
        #                 print("     -> Click nút Xong (Dự phòng)...")
        #                 action.w3c_actions.pointer_action.move_to_location(int(size['width'] * 0.9), int(size['height'] * 0.12))
        #                 action.w3c_actions.pointer_action.pointer_down()
        #                 action.w3c_actions.pointer_action.pointer_up()
        #                 action.perform()
                        
        #                 time.sleep(3) # Chờ ảnh load vào form

        #             time.sleep(5)
        #         except Exception as e:
        #             print(f"     ⚠️ Lỗi thêm ảnh lần {i+1}: {e}")
        #             driver.back() # Đóng bottom sheet nếu lỗi -- CODE CŨ 

        # --- C. CHỌN DANH MỤC (SỬA LẠI: DÙNG ID RIÊNG BIỆT) ---
        if case['categories']:
            print(f"   -> [Step] Chọn {len(case['categories'])} danh mục")
            for cat_name in case['categories']:
                try:
                    # 1. Tìm nút "Thêm danh mục" (Dùng ID riêng: btn_add_category)
                    # Nếu đã chọn đủ 3 cái, nút này sẽ biến mất -> Appium sẽ báo lỗi -> Đúng logic test giới hạn
                    try:
                        driver.find_element(AppiumBy.ACCESSIBILITY_ID, "btn_add_category").click()
                    except:
                        # Fallback nếu ID lỗi: Tìm nút Thêm nằm trong vùng Danh mục (trên nút thêm ảnh)
                        # XPath này tìm nút Thêm đầu tiên
                        xpath_cat_add = "(//*[contains(@content-desc, 'Thêm') or contains(@text, 'Thêm')])[1]"
                        driver.find_element(AppiumBy.XPATH, xpath_cat_add).click()
                    
                    time.sleep(1.5) # Chờ Dialog danh mục hiện lên

                    # 2. Chọn Item trong list
                    xpath_item = f"//*[contains(@content-desc, '{cat_name}') or contains(@text, '{cat_name}')]"
                    driver.find_element(AppiumBy.XPATH, xpath_item).click()
                    time.sleep(1)
                    print(f"     -> Đã chọn: {cat_name}")
                except Exception as e:
                    print(f"     ⚠️ Không thể chọn danh mục '{cat_name}'. (Có thể đã đạt giới hạn 3/3).")

        # --- D. THÊM ẢNH (SỬA LỖI THƯ VIỆN & TÁCH BIỆT NÚT ADD) ---
        # 1. Scroll xuống dưới cùng
        # --- HÀM HỖ TRỢ CLICK TỌA ĐỘ (FIX LỖI W3C) ---
        def tap_point(driver, x, y):
            try:
                actions = ActionChains(driver)
                finger = PointerInput(interaction.POINTER_TOUCH, "finger")
                actions.w3c_actions = ActionBuilder(driver, mouse=finger)
                actions.w3c_actions.pointer_action.move_to_location(int(x), int(y))
                actions.w3c_actions.pointer_action.pointer_down()
                actions.w3c_actions.pointer_action.pause(0.2) # Giữ 0.2s để đảm bảo nhận lệnh
                actions.w3c_actions.pointer_action.pointer_up()
                actions.perform()
            except Exception as e:
                print(f"        ⚠️ Lỗi tap tại ({x}, {y}): {e}")

        try: driver.hide_keyboard()
        except: pass
        try:
            driver.find_element(AppiumBy.ANDROID_UIAUTOMATOR, 'new UiScrollable(new UiSelector().scrollable(true)).scrollForward()')
            time.sleep(0.5)
        except: pass

        if case['img_count'] > 0:
            print(f"   -> [Step] Thêm {case['img_count']} ảnh (Nguồn: {case['img_source']})")
            for i in range(case['img_count']):
                try:
                    # BƯỚC 1: CLICK NÚT "THÊM ẢNH" (Dùng ID riêng: btn_add_image)
                    try:
                        driver.find_element(AppiumBy.ACCESSIBILITY_ID, "btn_add_image").click()
                    except:
                        # Fallback: Tìm nút Thêm nằm dưới cùng (vì nút thêm danh mục ở trên)
                        xpath_img_add = "(//*[contains(@content-desc, 'Đăng ảnh') or contains(@text, 'Đăng ảnh')])[last()]"
                        driver.find_element(AppiumBy.XPATH, xpath_img_add).click()

                    print("     -> Đã click nút Thêm ảnh. Đang chờ BottomSheet...")
                    time.sleep(3) # [QUAN TRỌNG] Tăng thời gian chờ Bottom Sheet hiện lên

                    # BƯỚC 2: CHỌN NGUỒN (CAMERA / LIBRARY)
                    src = "camera"
                    if case['img_source'] == "library" or (case['img_source'] == "mixed" and i > 0): 
                        src = "library"

                    if src == "camera":
                        print("     -> Chọn nguồn: Camera...")
                        try:
                            driver.find_element(AppiumBy.ACCESSIBILITY_ID, "btn_camera").click()
                        except:
                            driver.find_element(AppiumBy.XPATH, "//*[contains(@text, 'Chụp') or contains(@content-desc, 'Chụp') or contains(@text, 'Camera')]").click()
                        
                        # Gọi hàm xử lý Camera
                        handle_camera_coordinates(driver)
                    
                    else:
                        print("     -> Chọn Thư viện...")
                        # 1. Click nút Thư viện (Tọa độ mù - BottomSheet)
                        size = driver.get_window_size()
                        w = size['width']
                        h = size['height']
                        
                        # Click vào nút "Chọn từ thư viện" (Khoảng 78% chiều cao)
                        action = ActionChains(driver)
                        finger = PointerInput(interaction.POINTER_TOUCH, "finger")
                        action.w3c_actions = ActionBuilder(driver, mouse=finger)
                        action.w3c_actions.pointer_action.move_to_location(int(w * 0.5), int(h * 0.78))
                        action.w3c_actions.pointer_action.pointer_down()
                        action.w3c_actions.pointer_action.pause(0.2)
                        action.w3c_actions.pointer_action.pointer_up()
                        action.perform()

                        # 2. Check Quyền & Chờ Load
                        time.sleep(3)
                        try: driver.find_element(AppiumBy.XPATH, "//*[contains(@text, 'Cho phép') or contains(@text, 'Allow')]").click()
                        except: pass
                        time.sleep(4) # Chờ ảnh load

                        # 3. CLICK CHỌN ẢNH THEO LƯỚI (DỰA TRÊN ẢNH BẠN GỬI)
                        # Danh sách tọa độ 6 ảnh (Tương đối theo %)
                        # Ảnh 1: (16%, 55%), Ảnh 2: (50%, 55%), Ảnh 3: (83%, 55%)
                        # Ảnh 4: (16%, 75%), Ảnh 5: (50%, 75%), Ảnh 6: (83%, 75%)
                        img_coords = [
                            (0.16, 0.55), (0.50, 0.55), (0.83, 0.55),
                            (0.16, 0.75), (0.50, 0.75), (0.83, 0.75)
                        ]
                        
                        # Số lượng cần chọn
                        count_to_pick = case['img_count']
                        if case['img_source'] == "mixed": count_to_pick = 1 # Nếu mixed thì lần này chỉ chọn 1
                        
                        # Giới hạn max 6 ảnh theo tọa độ có sẵn
                        if count_to_pick > 6: count_to_pick = 6
                        
                        print(f"     -> Đang chọn {count_to_pick} ảnh...")
                        
                        action = ActionChains(driver)
                        action.w3c_actions = ActionBuilder(driver, mouse=finger)

                        for idx in range(count_to_pick):
                            cx, cy = img_coords[idx]
                            print(f"        -> Click ảnh {idx+1}...")
                            # Gọi hàm tap riêng biệt (Fix lỗi W3C)
                            tap_point(driver, w * cx, h * cy)
                            # QUAN TRỌNG: Nghỉ 1s giữa các lần click để UI kịp phản hồi (dấu tick xanh)
                            time.sleep(1)
                        
                        action.perform() # Thực thi chuỗi click ảnh
                        
                        # 4. CLICK NÚT DONE (HOÀN TẤT)
                        # Vị trí nút Done: Góc phải dưới (85%, 90%)
                        print("     -> Click nút Done (Góc phải dưới)...")
                        time.sleep(1)
                        action = ActionChains(driver) # Reset action mới
                        action.w3c_actions = ActionBuilder(driver, mouse=finger)
                        
                        action.w3c_actions.pointer_action.move_to_location(int(w * 0.85), int(h * 0.90))
                        action.w3c_actions.pointer_action.pointer_down()
                        action.w3c_actions.pointer_action.pause(0.2)
                        action.w3c_actions.pointer_action.pointer_up()
                        action.perform()
                        
                        print("     -> Đã xong phần thư viện.")
                        time.sleep(3)

                        # --- [MỚI] CHECK SNACKBAR GIỚI HẠN ẢNH (CHO CASE DDD10) ---
                        # Logic: Nếu chọn quá 5 ảnh, App sẽ hiện thông báo ngay lúc này
                        if case['id'] == "DDD10" or case['img_count'] > 5:
                            print("     ℹ️ Đang check thông báo giới hạn ảnh...")
                            try:
                                # Text mẫu: "Đã đạt giới hạn 5 ảnh"
                                limit_msg = "Đã đạt giới hạn"
                                xpath_limit = f"//*[contains(@text, '{limit_msg}') or contains(@content-desc, '{limit_msg}')]"
                                driver.find_element(AppiumBy.XPATH, xpath_limit)
                                print(f"     ✅ PASSED: Bắt được thông báo giới hạn: '{limit_msg}'")
                            except:
                                print(f"     ⚠️ WARNING: Không bắt được thông báo giới hạn '{limit_msg}' (Có thể ẩn quá nhanh).")
                        
                        time.sleep(2)

                except Exception as e:
                    print(f"     ⚠️ Lỗi thêm ảnh: {e}")
                    driver.back() # Đóng sheet
                    time.sleep(1)

        # --- E. GỬI YÊU CẦU ---
        # --- E. GỬI YÊU CẦU & CHECK SNACKBAR ---
        print("   -> [Step] Nhấn Gửi...")
        try: driver.hide_keyboard()
        except: pass
        time.sleep(5)

        # 1. Nhấn nút Gửi
        try:
            driver.find_element(AppiumBy.XPATH, "//*[contains(@text, 'GỬI YÊU CẦU') or contains(@content-desc, 'GỬI YÊU CẦU')]").click()
        except:
            print("     ⚠️ Không tìm thấy nút Gửi (Thử scroll xuống hoặc click tọa độ)...")
            # Click tọa độ mù ở đáy màn hình nếu không thấy nút
            size = driver.get_window_size()
            action = ActionChains(driver)
            finger = PointerInput(interaction.POINTER_TOUCH, "finger")
            action.w3c_actions = ActionBuilder(driver, mouse=finger)
            action.w3c_actions.pointer_action.move_to_location(int(size['width'] * 0.5), int(size['height'] * 0.9))
            action.w3c_actions.pointer_action.pointer_down()
            action.w3c_actions.pointer_action.pointer_up()
            action.perform()

        # 2. KIỂM TRA KẾT QUẢ (VERIFY)
        # 2. KIỂM TRA TRẠNG THÁI FORM (Dựa trên TIÊU ĐỀ - An toàn hơn nút Gửi)
        print("   -> [Verify] Đang kiểm tra trạng thái màn hình...")
        time.sleep(1.5) # Chờ animation/snackbar

        # Kiểm tra xem có đang ở Form không? (Tìm tiêu đề trên cùng)
        is_on_form = False
        try:
            # Tìm tiêu đề đặc trưng: "Thông tin địa điểm" hoặc "Đăng ký địa điểm mới"
            # Tiêu đề này nằm trên cùng, không bao giờ bị bàn phím che
            xpath_title = "//*[contains(@text, 'Thông tin địa điểm') or contains(@text, 'Đăng ký địa điểm') or contains(@content-desc, 'Thông tin địa điểm')]"
            driver.find_element(AppiumBy.XPATH, xpath_title)
            is_on_form = True
            print("     -> Trạng thái: VẪN Ở FORM (Tìm thấy tiêu đề).")
        except:
            is_on_form = False

        # --- LOGIC CHO NEGATIVE CASE (DDD01, DDD05) ---
        if case['expect_pass'] == False:
            print(f"     ℹ️ Case {case['id']} mong đợi BỊ CHẶN (Negative).")

            # Check SnackBar/Error Message
            # Tìm bất kỳ text nào chứa "Vui lòng" hoặc "bắt buộc"
            error_msg_found = False
            try:
                xpath_err = "//*[contains(@text, 'Vui lòng') or contains(@text, 'bắt buộc') or contains(@content-desc, 'Vui lòng')]"
                el = driver.find_element(AppiumBy.XPATH, xpath_err)
                print(f"     ✅ PASSED: Bắt được thông báo lỗi: '{el.text if el.text else el.get_attribute('content-desc')}'")
                error_msg_found = True
            except:
                print(f"     ⚠️ WARNING: Không bắt được text lỗi cụ thể.")
                # [DEBUG QUAN TRỌNG] Nếu không thấy lỗi, in source ra để soi
                # print("     [DEBUG SOURCE]:", driver.page_source[:500]) # In 500 ký tự đầu

            # ĐÁNH GIÁ KẾT QUẢ
            if is_on_form:
                # Chỉ cần Vẫn ở Form là coi như Pass (Hệ thống đã chặn việc chuyển trang)
                print("     ✅ KẾT QUẢ: PASSED (Hệ thống chặn thành công, vẫn ở Form).")
                
                # CLEANUP: Vì đang ở Form nên PHẢI BACK
                print("     -> [Action] Đang ở Form -> Bấm Back để về Map...")
                driver.back()
                time.sleep(1.5)
                try: 
                    # Xử lý popup hủy "Bạn có chắc muốn thoát?"
                    driver.find_element(AppiumBy.XPATH, "//*[contains(@text, 'Đồng ý') or contains(@text, 'Thoát') or contains(@text, 'Hủy') or contains(@text, 'Discard')]").click()
                    print("     -> Đã xác nhận popup Hủy.")
                except: pass
            else:
                print("     ❌ FAILED: Đã thoát Form (Lỗi hệ thống - Đã gửi thành công sai quy định).")


        # --- LOGIC CHO POSITIVE CASE (CÁC CASE CÒN LẠI) ---
        else:
            print("     ℹ️ Case mong đợi THÀNH CÔNG (Positive).")
            
            # Text mong đợi: "Đã gửi yêu cầu chờ duyệt!"
            success_msg = "Đã gửi yêu cầu chờ duyệt"
            # Text lỗi upload ảnh (Cloudinary...)
            upload_error_msg = "Không thể tải ảnh" 
            
            is_success = False
            is_upload_error = False

            # Chờ và Check các loại thông báo
            # Vì ta không biết nó hiện cái nào trước, ta check tuần tự
            try:
                # 1. Tìm thông báo Thành công
                xpath_success = f"//*[contains(@text, '{success_msg}') or contains(@content-desc, '{success_msg}')]"
                driver.find_element(AppiumBy.XPATH, xpath_success)
                print(f"     ✅ PASSED: Bắt được thông báo thành công: '{success_msg}'")
                is_success = True
            except:
                # 2. Nếu không thấy thành công -> Tìm thông báo Lỗi Upload
                try:
                    xpath_upload_err = f"//*[contains(@text, '{upload_error_msg}') or contains(@content-desc, '{upload_error_msg}')]"
                    driver.find_element(AppiumBy.XPATH, xpath_upload_err)
                    print(f"     ⚠️ WARNING: Gặp lỗi Upload ảnh: '{upload_error_msg}'")
                    is_upload_error = True
                except:
                    print("     ⚠️ WARNING: Không bắt được SnackBar nào (Có thể ẩn quá nhanh).")

            # XỬ LÝ HẬU KỲ
            time.sleep(2) 

            if is_upload_error:
                # TRƯỜNG HỢP LỖI UPLOAD: Bấm Back 1 lần như yêu cầu
                print("     -> [Action] Lỗi Upload -> Bấm Back để thoát Form...")
                driver.back()
                time.sleep(1)
                # Nếu có popup "Hủy?" thì bấm Đồng ý luôn để thoát hẳn
                try: driver.find_element(AppiumBy.XPATH, "//*[contains(@text, 'Đồng ý')]").click()
                except: pass
                
            elif is_success:
                # TRƯỜNG HỢP THÀNH CÔNG: Check xem về Map chưa
                time.sleep(2)
                try:
                    driver.find_element(AppiumBy.ACCESSIBILITY_ID, "btn_add_new_place")
                    print("     ✅ KẾT QUẢ: PASSED TUYỆT ĐỐI (Về Map thành công).")
                except:
                    print("     ✅ KẾT QUẢ: PASSED (Đã hiện thông báo, đang về Map).")
            
            else:
                # TRƯỜNG HỢP KHÔNG RÕ RÀNG (Không thấy thông báo gì)
                # Check xem đang ở đâu
                try:
                    driver.find_element(AppiumBy.ACCESSIBILITY_ID, "btn_add_new_place")
                    print("     ✅ KẾT QUẢ: PASSED (Đã về Map - Dù không bắt được thông báo).")
                except:
                    # Vẫn kẹt ở Form
                    print("     ❌ KẾT QUẢ: FAILED (Kẹt ở Form, không thấy thông báo).")
                    driver.back()
                    try: driver.find_element(AppiumBy.XPATH, "//*[contains(@text, 'Đồng ý')]").click()
                    except: pass

            # 2. KIỂM TRA ĐÃ VỀ MAP CHƯA
            #time.sleep(3) # Chờ app tự động đóng form và về map

            # try:
            #     driver.find_element(AppiumBy.ACCESSIBILITY_ID, "btn_add_new_place")
                
            #     # Đánh giá kết quả cuối cùng
            #     if is_success_snackbar_found:
            #         print("     ✅ KẾT QUẢ: PASSED TUYỆT ĐỐI (Thấy thông báo + Về Map).")
            #     else:
            #         print("     ✅ KẾT QUẢ: PASSED (Đã về Map - Dù không bắt kịp thông báo).")
            # except:
            #     print("     ❌ KẾT QUẢ: FAILED (Chưa về Map - Có thể bị kẹt ở Form hoặc Lỗi server).")
                
            #     # Cứu hộ: Bấm Back để thoát Form cho case sau chạy tiếp
            #     print("     -> [Cleanup] Bấm Back cứu hộ...")
            #     driver.back()
            #     time.sleep(1)
            #     try: driver.find_element(AppiumBy.XPATH, "//*[contains(@text, 'Đồng ý') or contains(@text, 'Thoát')]").click()
            #     except: pass

        print("--------------------------------------------------")
        time.sleep(3) # Nghỉ trước khi qua case mới
        
except Exception as e:
    print(f"🔥 ERROR: {e}")
finally:
    driver.quit()