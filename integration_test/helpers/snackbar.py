import time
from appium.webdriver.common.appiumby import AppiumBy
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC


def expect_snackbar(driver, expected_text, timeout=10, is_error=False):
    """
    Kiểm tra SnackBar xuất hiện với nội dung mong đợi.
    SnackBar trong Flutter biến mất rất nhanh, cần check liên tục.
    """
    print(f"   🔍 Đang đợi SnackBar: '{expected_text}'...")
    
    # LƯU LẠI implicit wait hiện tại (CÁCH AN TOÀN)
    try:
        # Lấy implicit wait hiện tại bằng cách execute_script
        original_implicit_wait = driver.execute_script("return arguments[0].manage().timeouts().implicitlyWait;")
    except:
        # Fallback: giả sử là 3s (mặc định)
        original_implicit_wait = 3
    
    # GIẢM IMPLICIT WAIT để check nhanh hơn
    driver.implicitly_wait(0.5)
    
    start_time = time.time()
    found = False
    
    try:
        while time.time() - start_time < timeout:
            # Chiến thuật: Check liên tục mỗi 0.5s
            strategies = [
                # Tìm theo text chính xác
                (AppiumBy.XPATH, f'//*[@text="{expected_text}"]'),
                # Tìm theo contains
                (AppiumBy.XPATH, f'//*[contains(@text, "{expected_text}")]'),
                # Tìm trong SnackBar widget của Flutter
                (AppiumBy.XPATH, f'//android.view.View[contains(@content-desc, "{expected_text}")]'),
            ]
            
            for strategy_type, locator in strategies:
                try:
                    elements = driver.find_elements(strategy_type, locator)
                    
                    if elements and len(elements) > 0:
                        # Tìm thấy!
                        icon = "❌" if is_error else "✅"
                        print(f"   {icon} Đã tìm thấy SnackBar: '{expected_text}'")
                        found = True
                        break
                        
                except Exception:
                    continue
            
            if found:
                break
            
            # Chờ 0.5s rồi thử lại
            time.sleep(0.5)
        
        if not found:
            # Không tìm thấy sau timeout
            print(f"   ❌ KHÔNG tìm thấy SnackBar: '{expected_text}'")
            
            # Debug: Chụp screenshot
            try:
                screenshot_name = f"snackbar_not_found_{int(time.time())}.png"
                driver.save_screenshot(screenshot_name)
                print(f"   📸 Đã chụp screenshot: {screenshot_name}")
            except:
                pass
        
    finally:
        # QUAN TRỌNG: Khôi phục implicit wait trong finally block
        driver.implicitly_wait(original_implicit_wait)
    
    # Chờ SnackBar biến mất nếu tìm thấy
    if found:
        time.sleep(2)
    
    return found


def expect_snackbar_sequence(driver, text_sequence, timeout_each=10):
    """
    Kiểm tra chuỗi SnackBar xuất hiện theo thứ tự.
    
    Ví dụ: ["Đang xử lý...", "Đăng bài check-in thành công!"]
    
    Args:
        driver: Appium WebDriver instance
        text_sequence: List các text mong đợi theo thứ tự
        timeout_each: Timeout cho mỗi SnackBar
    
    Returns:
        True nếu tất cả SnackBar xuất hiện đúng thứ tự
    """
    print(f"   📋 Kiểm tra chuỗi {len(text_sequence)} SnackBar...")
    
    for i, expected_text in enumerate(text_sequence, 1):
        print(f"   [{i}/{len(text_sequence)}] Chờ: '{expected_text}'")
        
        if not expect_snackbar(driver, expected_text, timeout=timeout_each):
            print(f"   ❌ Chuỗi SnackBar bị gián đoạn tại bước {i}")
            return False
        
        # Chờ một chút giữa các SnackBar
        time.sleep(1)
    
    print(f"   ✅ Tất cả {len(text_sequence)} SnackBar xuất hiện đúng thứ tự")
    return True


def expect_validation_error(driver, field_name):
    """
    Kiểm tra lỗi validation cho từng field cụ thể.
    
    Args:
        driver: Appium WebDriver instance
        field_name: Tên field ('image', 'title', 'comment', 'place')
    
    Returns:
        True nếu SnackBar lỗi đúng xuất hiện
    """
    error_messages = {
        'image': 'Vui lòng thêm ít nhất một ảnh.',
        'image_max': 'Vui lòng thêm tối đa 10 ảnh.',
        'title': 'Vui lòng nhập Tiêu đề.',
        'comment': 'Vui lòng nhập Nội dung.',
        'place': 'Vui lòng chọn địa điểm.',
    }
    
    expected_message = error_messages.get(field_name)
    
    if not expected_message:
        print(f"   ⚠️ Không tìm thấy message cho field: {field_name}")
        return False
    
    return expect_snackbar(driver, expected_message, timeout=5, is_error=True)