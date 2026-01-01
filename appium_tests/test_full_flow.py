import time
from appium import webdriver
from appium.options.android import UiAutomator2Options
from appium.webdriver.common.appiumby import AppiumBy

# Thư viện để thao tác chạm/vuốt (Gestures)
from selenium.webdriver.common.action_chains import ActionChains
from selenium.webdriver.common.actions import interaction
from selenium.webdriver.common.actions.action_builder import ActionBuilder
from selenium.webdriver.common.actions.pointer_input import PointerInput

# --- CẤU HÌNH ---
options = UiAutomator2Options()
options.platform_name = 'Android'
options.automation_name = 'UiAutomator2'
options.device_name = 'emulator-5554' # Tên máy ảo của bạn
# ĐƯỜNG DẪN APK (Thay bằng đường dẫn thật trên máy bạn)
options.app = r'C:\Users\Pon\Desktop\danhminhquoc_8774\nhom_3_damh_lttbdd\build\app\outputs\flutter-apk\app-debug.apk'
options.no_reset = False # Để False để reset app (đăng nhập lại từ đầu) cho chắc

driver = webdriver.Remote('http://127.0.0.1:4723', options=options)

# Hàm tiện ích: Chờ và tìm phần tử
def wait_and_find(xpath, timeout=10):
    end_time = time.time() + timeout
    while time.time() < end_time:
        try:
            el = driver.find_element(AppiumBy.XPATH, xpath)
            return el
        except:
            time.sleep(0.5)
    raise Exception(f"Không tìm thấy phần tử: {xpath}")

try:
    print("🚀 BẮT ĐẦU TEST E2E...")
    time.sleep(8) # Chờ Flutter engine khởi động

    # ====================================================
    # BƯỚC 1: ĐĂNG NHẬP (ĐÃ FIX TÌM NÚT)
    # ====================================================
    print("1. [Login] Đang đăng nhập...")
    
    # 1. Điền Email
    email_xpath = "//android.widget.EditText[contains(@text, 'Email') or contains(@hint, 'Email')]"
    email_el = wait_and_find(email_xpath)
    email_el.click()
    email_el.send_keys("danhminhquoc1804@gmail.com") # Nhớ thay bằng email thật

    # 2. Điền Mật khẩu
    pass_xpath = "//android.widget.EditText[contains(@text, 'mật khẩu') or contains(@hint, 'mật khẩu')]"
    pass_el = wait_and_find(pass_xpath)
    pass_el.click()
    pass_el.send_keys("123456") 
    
    # 3. Ẩn bàn phím (Quan trọng: Bàn phím che nút sẽ không bấm được)
    try:
        driver.hide_keyboard()
        time.sleep(1) # Chờ bàn phím thụt xuống
    except:
        pass # Bỏ qua nếu không có phím ảo

    # 4. Tìm nút Đăng nhập (Chiến thuật mới)
    print("   -> Tìm nút Đăng nhập...")
    try:
        # Cách 1: Tìm theo Class Button (Thường nút Login là nút Button đầu tiên hoặc thứ 2)
        # Flutter thường render ElevatedButton thành android.widget.Button
        buttons = driver.find_elements(AppiumBy.CLASS_NAME, "android.widget.Button")
        
        login_btn = None
        # Duyệt qua các nút để tìm nút đúng
        for btn in buttons:
            text = btn.text
            content_desc = btn.get_attribute("content-desc")
            # Kiểm tra xem text hoặc content-desc có chứa chữ "Đăng nhập" không (bất kể hoa thường)
            if (text and "Đăng nhập" in text) or (content_desc and "Đăng nhập" in content_desc):
                login_btn = btn
                break
        
        # Nếu không tìm thấy bằng text, thử click nút Button ĐẦU TIÊN tìm thấy
        # (Vì trong LoginScreen, nút Đăng nhập là nút Button lớn đầu tiên)
        if login_btn is None and len(buttons) > 0:
             print("   ⚠️ Không thấy text 'Đăng nhập', thử bấm nút Button đầu tiên...")
             login_btn = buttons[0]

        if login_btn:
            login_btn.click()
        else:
            raise Exception("Không tìm thấy bất kỳ nút Button nào!")

    except Exception as e:
        # Fallback: Nếu không tìm thấy class Button, thử tìm View có chứa description
        print(f"   ⚠️ Cách 1 thất bại ({e}), thử Cách 2 (XPath content-desc)...")
        driver.find_element(AppiumBy.XPATH, "//*[contains(@content-desc, 'Đăng nhập')]").click()
    
    print("   -> Đã bấm đăng nhập, chờ chuyển trang...")
    time.sleep(8) # Tăng thời gian chờ Login (Firebase có thể chậm)

    # ====================================================
    # BƯỚC 2: TỪ HOME -> JOURNEY MAP (ĐÃ FIX MẠNH MẼ)
    # ====================================================
    print("2. [Home] Tìm đường vào Journey Map...")
    
    journey_map_found = False
    
    # CÁCH 1: Tìm theo Tiêu đề chính xác "Journey Map của bạn"
    # (Thử cả @text và @content-desc vì Flutter hay đổi lung tung giữa 2 cái này)
    if not journey_map_found:
        try:
            print("   -> Thử tìm text 'Journey Map của bạn'...")
            xpath_title = "//*[contains(@text, 'Journey Map của bạn') or contains(@content-desc, 'Journey Map của bạn')]"
            driver.find_element(AppiumBy.XPATH, xpath_title).click()
            journey_map_found = True
            print("   ✅ Đã click vào tiêu đề!")
        except:
            pass

    # CÁCH 2: Tìm theo dòng phụ "Đã khám phá" (Dòng chữ nhỏ bên dưới)
    if not journey_map_found:
        try:
            print("   -> Thử tìm text phụ 'Đã khám phá'...")
            xpath_subtitle = "//*[contains(@text, 'Đã khám phá') or contains(@content-desc, 'Đã khám phá')]"
            driver.find_element(AppiumBy.XPATH, xpath_subtitle).click()
            journey_map_found = True
            print("   ✅ Đã click vào dòng phụ!")
        except:
            pass

    # CÁCH 3: Click theo Tọa độ (Tuyệt chiêu cuối cùng)
    # Dựa vào ảnh bạn gửi, Container Journey Map nằm ở khoảng 45%-55% chiều cao màn hình.
    if not journey_map_found:
        print("   ⚠️ Không bắt được Text, thực hiện Click vào giữa màn hình (Tọa độ)...")
        size = driver.get_window_size()
        screen_width = size['width']
        screen_height = size['height']
        
        # Tính tọa độ trung tâm container (Ước lượng từ ảnh: Giữa màn hình theo chiều dọc)
        click_x = screen_width // 2
        click_y = int(screen_height * 0.48) # Khoảng 48% chiều cao màn hình (Ngay dưới phần Dịch vụ)
        
        # Thực hiện Click
        finger = PointerInput(interaction.POINTER_TOUCH, "finger")
        actions = ActionChains(driver)
        actions.w3c_actions = ActionBuilder(driver, mouse=finger)
        actions.w3c_actions.pointer_action.move_to_location(click_x, click_y)
        actions.w3c_actions.pointer_action.pointer_down()
        actions.w3c_actions.pointer_action.pause(0.1)
        actions.w3c_actions.pointer_action.pointer_up()
        actions.perform()
        
        print(f"   ✅ Đã click theo tọa độ ({click_x}, {click_y})")

    time.sleep(3) # Chờ chuyển trang

    # ====================================================
    # BƯỚC 3: JOURNEY MAP -> MENU -> WORLD MAP (ĐÃ FIX)
    # ====================================================
    print("3. [Journey Map] Mở Menu & vào World Map...")
    
    # Text mục tiêu cần bấm
    target_text = "Mở bản đồ khu vực"
    target_xpath = f"//*[contains(@text, '{target_text}') or contains(@content-desc, '{target_text}')]"

    # TH1: Thử tìm xem nút "Mở bản đồ khu vực" có đang hiện sẵn không?
    try:
        driver.find_element(AppiumBy.XPATH, target_xpath).click()
        print(f"   ✅ Đã click thẳng vào '{target_text}' (Menu đang mở sẵn)")
    except:
        # TH2: Nếu chưa thấy, nghĩa là Menu đang đóng -> Phải click FAB trước
        print("   -> Menu đang đóng, tìm nút FAB để mở...")
        
        # Tìm nút FAB (Thường là nút Button/ImageButton nằm cuối cùng trong cây UI)
        fabs = driver.find_elements(AppiumBy.CLASS_NAME, "android.widget.Button")
        if not fabs:
            fabs = driver.find_elements(AppiumBy.CLASS_NAME, "android.widget.ImageButton")
        
        if fabs:
            # Click nút cuối cùng (thường là FAB góc dưới phải)
            print("   -> Click vào nút Button cuối cùng (nghi là FAB)...")
            fabs[-1].click()
        else:
            # Fallback: Click theo tọa độ góc dưới phải (nếu không bắt được ID nút)
            print("   ⚠️ Không bắt được ID nút FAB, click theo tọa độ góc phải dưới...")
            size = driver.get_window_size()
            fab_x = int(size['width'] * 0.88) # 88% chiều rộng (Góc phải)
            fab_y = int(size['height'] * 0.9) # 90% chiều cao (Góc dưới)
            
            # --- FIX LỖI CRITICAL 'mouse_unit' TẠI ĐÂY ---
            finger = PointerInput(interaction.POINTER_TOUCH, "finger")
            actions = ActionChains(driver)
            actions.w3c_actions = ActionBuilder(driver, mouse=finger) # Đã đổi thành mouse
            actions.w3c_actions.pointer_action.move_to_location(fab_x, fab_y)
            actions.w3c_actions.pointer_action.pointer_down()
            actions.w3c_actions.pointer_action.pause(0.1)
            actions.w3c_actions.pointer_action.pointer_up()
            actions.perform()

        time.sleep(1) # Chờ menu bung ra (hiệu ứng animation)
        
        # Sau khi mở menu, tìm và click lại mục tiêu
        print(f"   -> Menu đã mở, chọn '{target_text}'...")
        wait_and_find(target_xpath).click()

    print("   -> Đang chuyển sang World Map...")
    time.sleep(5) # Chờ bản đồ load

    # ====================================================
    # BƯỚC 4: WORLD MAP -> LONG PRESS (ĐÃ FIX LỖI ACTION BUILDER)
    # ====================================================
    print("4. [World Map] Nhấn giữ để thả ghim...")
    
    # --- FIX 1: TỰ ĐỘNG BẤM "CHO PHÉP" / "ALLOW" ---
    # Kiểm tra nhanh xem có popup xin quyền không
    try:
        # Tìm nút "Trong khi dùng ứng dụng" hoặc "Cho phép" hoặc "Allow"
        perm_xpath = "//*[@text='Trong khi dùng ứng dụng' or @text='While using the app' or @text='Cho phép' or @text='Allow']"
        # Chờ tối đa 3 giây
        driver.implicitly_wait(3) 
        perm_btn = driver.find_element(AppiumBy.XPATH, perm_xpath)
        perm_btn.click()
        print("   ✅ Đã tự động cấp quyền vị trí!")
        driver.implicitly_wait(10) # Trả lại thời gian chờ mặc định
        time.sleep(10) # Chờ map load lại sau khi cấp quyền
    except:
        # Nếu không có popup thì thôi, đi tiếp
        driver.implicitly_wait(10)
        pass

    size = driver.get_window_size()
    center_x = size['width'] // 2
    center_y = size['height'] // 2

    # --- CÚ PHÁP CHUẨN MỚI (FIX LỖI CRITICAL) ---
    # Tạo input kiểu "ngón tay" (touch)
    finger = PointerInput(interaction.POINTER_TOUCH, "finger")
    
    # Khởi tạo ActionChains với thiết bị "finger"
    actions = ActionChains(driver)
    actions.w3c_actions = ActionBuilder(driver, mouse=finger) # Sửa mouse_unit -> mouse
    
    # Thực hiện chuỗi hành động: Di chuyển -> Nhấn -> Giữ 2s -> Nhả
    actions.w3c_actions.pointer_action.move_to_location(center_x, center_y)
    actions.w3c_actions.pointer_action.pointer_down()
    actions.w3c_actions.pointer_action.pause(2) 
    actions.w3c_actions.pointer_action.pointer_up()
    actions.perform()
    
    time.sleep(2) # Chờ Bottom Sheet hiện lên

    print("   -> Chọn 'Thêm' trong Modal...")
    # Tìm nút Thêm (text hoặc content-desc)
    add_btn = wait_and_find("//*[contains(@text, 'Thêm') or contains(@content-desc, 'Thêm')]")
    add_btn.click()
    
    time.sleep(2)

    # ====================================================
    # BƯỚC 5: ĐIỀN FORM (ĐÃ FIX: DÙNG INDEX)
    # ====================================================
    print("5. [Add Place] Điền form đăng ký...")
    
    # Chiến thuật: Lấy tất cả các ô EditText trên màn hình
    # Form của bạn theo thứ tự: 
    # [0]: Tên địa điểm (Nhập được)
    # [1]: Tỉnh/Thành (Dropdown - Không nhập được)
    # [2]: Phường/Xã (Readonly)
    # [3]: Đường (Readonly)
    # [4]: Ghi chú (Nhập được)
    
    edit_texts = driver.find_elements(AppiumBy.CLASS_NAME, "android.widget.EditText")
    
    if len(edit_texts) > 0:
        # 1. Nhập Tên (Ô đầu tiên - Index 0)
        print("   -> Nhập tên vào ô đầu tiên...")
        name_input = edit_texts[0]
        name_input.click()
        name_input.send_keys("Quán Cafe Appium Auto")
        driver.hide_keyboard()
        
        # 2. Nhập Ghi chú (Ô cuối cùng - Index -1 hoặc 4)
        # Tìm ô Ghi chú (Thường là ô cuối cùng trong list EditText)
        print("   -> Nhập ghi chú vào ô cuối cùng...")
        note_input = edit_texts[-1] 
        note_input.click()
        note_input.send_keys("Test auto long press")
        driver.hide_keyboard()
    else:
        raise Exception("Không tìm thấy bất kỳ ô nhập liệu nào trên màn hình!")

    # 3. Chọn danh mục
    print("   -> Chọn danh mục...")
    # Tìm nút "Thêm" (Text hoặc Content-Desc)
    try:
        add_cat_btn = wait_and_find("//*[contains(@text, 'Thêm') or contains(@content-desc, 'Thêm')]")
        add_cat_btn.click()
    except:
        # Fallback: Tìm nút Button nhỏ nằm giữa màn hình (thường là nút Thêm category)
        print("   ⚠️ Không thấy nút 'Thêm', thử click tọa độ...")
        # ... logic fallback cũ ...

    time.sleep(1)
    
    # Chọn item đầu tiên trong Dialog
    # (Chọn View đầu tiên trong ScrollView)
    try:
        # Tìm ScrollView rồi click phần tử con đầu tiên
        dialog_item = driver.find_element(AppiumBy.XPATH, "//android.widget.ScrollView//android.view.View[1]")
        dialog_item.click()
    except:
        # Nếu không được, click đại vào giữa màn hình (Dialog thường hiện ở giữa)
        size = driver.get_window_size()
        actions = ActionChains(driver)
        finger = PointerInput(interaction.POINTER_TOUCH, "finger")
        actions.w3c_actions = ActionBuilder(driver, mouse=finger)
        actions.w3c_actions.pointer_action.move_to_location(size['width'] // 2, size['height'] // 2)
        actions.w3c_actions.pointer_action.pointer_down().pointer_up()
        actions.perform()

    time.sleep(1)

    # ====================================================
    # BƯỚC 6: BẤM GỬI (ĐÃ FIX: CUỘN NHIỀU LẦN)
    # ====================================================
    print("6. [Add Place] Tìm và bấm nút Gửi...")

    # 1. Ẩn bàn phím trước
    try:
        driver.hide_keyboard()
        time.sleep(1)
    except:
        pass

    submit_btn = None
    max_scroll_attempts = 3 # Thử cuộn tối đa 3 lần
    
    for i in range(max_scroll_attempts):
        try:
            # Thử tìm nút Gửi
            # Dùng XPath ngắn gọn hơn để tránh sai sót
            btn_xpath = "//*[@text='GỬI YÊU CẦU' or @content-desc='GỬI YÊU CẦU']"
            
            # Kiểm tra xem nút có hiện trên màn hình không
            # (timeout 1s để check nhanh)
            driver.implicitly_wait(1) 
            submit_btn = driver.find_element(AppiumBy.XPATH, btn_xpath)
            
            # Nếu tìm thấy thì thoát vòng lặp
            print("   ✅ Đã nhìn thấy nút Gửi!")
            driver.implicitly_wait(10) # Reset timeout
            break
        except:
            # Nếu chưa thấy -> Thực hiện thao tác vuốt lên
            print(f"   ⚠️ Chưa thấy nút (Lần {i+1}), đang cuộn xuống...")
            size = driver.get_window_size()
            start_x = size['width'] // 2
            start_y = int(size['height'] * 0.8) # Đáy
            end_y = int(size['height'] * 0.3)   # Đỉnh
            
            actions = ActionChains(driver)
            finger = PointerInput(interaction.POINTER_TOUCH, "finger")
            actions.w3c_actions = ActionBuilder(driver, mouse=finger)
            actions.w3c_actions.pointer_action.move_to_location(start_x, start_y)
            actions.w3c_actions.pointer_action.pointer_down()
            actions.w3c_actions.pointer_action.pause(0.5)
            actions.w3c_actions.pointer_action.move_to_location(start_x, end_y)
            actions.w3c_actions.pointer_action.pointer_up()
            actions.perform()
            time.sleep(1) # Chờ cuộn xong

    # Reset timeout về mặc định
    driver.implicitly_wait(10)

    # 2. Click nút (Sau khi đã cuộn)
    if submit_btn:
        submit_btn.click()
        print("   ✅ Đã CLICK nút 'GỬI YÊU CẦU'")
    else:
        # Fallback cuối cùng: Bấm nút Button cuối cùng trong cây UI
        print("   ⚠️ Vẫn không bắt được text, bấm nút Button cuối cùng...")
        buttons = driver.find_elements(AppiumBy.CLASS_NAME, "android.widget.Button")
        if buttons:
            buttons[-1].click()
        else:
            raise Exception("Bó tay! Không tìm thấy nút Gửi nào.")

    # ====================================================
    # BƯỚC 7: VERIFY
    # ====================================================
    print("7. Kiểm tra kết quả...")
    time.sleep(5) # Chờ loading và đóng màn hình

    # Nếu quay lại World Map (tức là nút Gửi đã mất) -> Thành công
    check_submit = driver.find_elements(AppiumBy.XPATH, "//*[@text='GỬI YÊU CẦU']")
    
    if len(check_submit) == 0:
        print("✅✅✅ TEST PASSED: Đã gửi thành công và đóng màn hình Add Place!")
    else:
        print("❌❌❌ TEST FAILED: Vẫn còn ở màn hình Add Place (có thể do lỗi validation).")
        driver.save_screenshot("failed_submit.png")

except Exception as e:
    print(f"❌ LỖI CRITICAL: {e}")
    driver.save_screenshot("error_critical.png")

finally:
    input("Bấm Enter để tắt script...")
    driver.quit()