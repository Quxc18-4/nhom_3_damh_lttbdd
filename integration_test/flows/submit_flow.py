import time
from appium.webdriver.common.appiumby import AppiumBy
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC

def submit_full_logic(driver, wait):
    """
    Đăng bài Check-in - GIỮ NGUYÊN 100% LOGIC GỐC
    """
    print("   🚀 Đăng bài (Logic đầy đủ)...")
    
    # 1. Cuộn xuống để nút hiển thị trong viewport
    driver.execute_script('mobile: scrollGesture', {
        'left': 200, 'top': 500, 'width': 600, 'height': 800,
        'direction': 'down', 'percent': 2.0
    })
    time.sleep(1)

    # 2. Tìm nút Đăng bài bằng nhiều chiến thuật
    submit_strategies = [
        (AppiumBy.ACCESSIBILITY_ID, "btn_submit_post"),
        (AppiumBy.XPATH, '//*[contains(@content-desc, "Đăng bài") or contains(@text, "Đăng bài")]'),
        (AppiumBy.CLASS_NAME, "android.widget.Button")  # ⚠️ FILE CŨ THIẾU DÒNG NÀY
    ]
    
    submit_btn = None
    for s_type, s_locator in submit_strategies:
        try:
            # ⚠️ FILE CŨ DÙNG find_element → SAI
            # PHẢI DÙNG WebDriverWait.until như gốc
            submit_btn = WebDriverWait(driver, 5).until(
                EC.element_to_be_clickable((s_type, s_locator))
            )
            if submit_btn:
                print(f"   ✅ Tìm thấy nút Đăng bài bằng: {s_type}")
                break
        except:
            continue

    if submit_btn:
        submit_btn.click()
        print("   🚀 Đã click Đăng bài! Đang chờ hệ thống xử lý (Lưu Firestore/Cloudinary)...")
        
        # 3. Chờ màn hình Home/Explore xuất hiện (DẤU HIỆU THÀNH CÔNG)
        # ⚠️ FILE CŨ THIẾU HOÀN TOÀN PHẦN NÀY
        try:
            wait_success = WebDriverWait(driver, 20)
            wait_success.until(EC.presence_of_element_located(
                (AppiumBy.XPATH, "//*[contains(@content-desc, 'Khám phá') or contains(@text, 'Khám phá')]")
            ))
            print("\n" + "="*60)
            print("🎉 CHÚC MỪNG: BÀI ĐĂNG ĐÃ ĐƯỢC GỬI THÀNH CÔNG!")
            print("="*60)
            return True
        except:
            print("   ⚠️ Đã nhấn nút nhưng chưa thấy chuyển màn hình. Có thể do mạng chậm.")
            return False
    else:
        raise Exception("❌ LỖI: Không thể tìm thấy nút 'Đăng bài' dù đã cuộn trang.")