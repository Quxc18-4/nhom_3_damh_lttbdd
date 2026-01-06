import time
from appium.webdriver.common.appiumby import AppiumBy
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC


def reset_checkin_by_back_and_reopen(driver, navigate_to_checkin_func):
    """
    ⭐ KHUYẾN NGHỊ: Reset form bằng cách quay lại Explore và mở lại Check-in.
    
    Đảm bảo form hoàn toàn sạch, không còn dữ liệu cũ.
    
    Args:
        driver: Appium WebDriver instance
        navigate_to_checkin_func: Hàm để mở lại màn hình Check-in
    
    Returns:
        True nếu thành công
    """
    print("   🔄 Reset form: Thoát về Explore và mở lại Check-in...")
    
    try:
        # 1. Thoát về màn hình Explore
        back_clicked = False
        
        # Thử 1: Tìm nút Back bằng key (ưu tiên nhất)
        try:
            back_btn = driver.find_element(
                AppiumBy.ACCESSIBILITY_ID,
                "btn_back_checkin"
            )
            back_btn.click()
            back_clicked = True
            print("   ✅ Đã click nút Back (by key)")
        except:
            pass
        
        # Thử 2: Tìm nút Back bằng XPATH
        if not back_clicked:
            try:
                back_btn = driver.find_element(
                    AppiumBy.XPATH,
                    '//android.widget.ImageButton'
                )
                back_btn.click()
                back_clicked = True
                print("   ✅ Đã click nút Back (by XPATH)")
            except:
                pass
        
        # Thử 3: Dùng hardware back button
        if not back_clicked:
            driver.back()
            print("   ✅ Đã nhấn hardware Back")
        
        time.sleep(2)
        
        # 2. Verify đã về Explore screen
        try:
            explore_indicator = driver.find_element(
                AppiumBy.XPATH,
                "//*[contains(@content-desc, 'Khám phá') or contains(@text, 'Khám phá')]"
            )
            print("   ✅ Đã quay về màn hình Khám phá")
        except:
            print("   ⚠️ Chưa thấy màn hình Khám phá (có thể đã ở Explore)")
        
        time.sleep(1)
        
        # 3. Mở lại Check-in screen
        print("   🔄 Đang mở lại màn hình Check-in...")
        navigate_to_checkin_func(driver)
        time.sleep(2)
        
        # 4. Verify Check-in screen đã mở
        driver.find_element(AppiumBy.XPATH, '//android.widget.EditText[1]')
        print("   ✅ Đã mở lại Check-in screen - Form đã reset hoàn toàn")
        
        return True
        
    except Exception as e:
        print(f"   ❌ Reset by back failed: {e}")
        # Debug: Chụp screenshot
        try:
            driver.save_screenshot(f"reset_failed_{int(time.time())}.png")
        except:
            pass
        return False


def clear_text_fields_only(driver):
    """
    ⚠️ FALLBACK: Chỉ xóa text fields (title & comment).
    
    LƯU Ý: 
    - Ảnh và địa điểm sẽ KHÔNG bị xóa
    - Chỉ dùng khi không thể reset bằng back
    - Không đảm bảo form hoàn toàn sạch
    
    Args:
        driver: Appium WebDriver instance
    
    Returns:
        True nếu xóa thành công text fields
    """
    print("   🧹 Xóa text fields (không xóa ảnh & địa điểm)...")
    
    # Scroll lên đầu
    try:
        driver.execute_script('mobile: scrollGesture', {
            'left': 100, 'top': 500, 'width': 200, 'height': 1000,
            'direction': 'up',
            'percent': 3.0
        })
        time.sleep(0.5)
    except:
        pass
    
    success = True
    
    # Clear Title
    try:
        title_field = driver.find_element(AppiumBy.XPATH, '//android.widget.EditText[1]')
        title_field.clear()
        print("   ✅ Đã xóa Tiêu đề")
    except Exception as e:
        print(f"   ⚠️ Không xóa được Tiêu đề: {e}")
        success = False
    
    # Clear Comment
    try:
        comment_field = driver.find_element(AppiumBy.XPATH, '//android.widget.EditText[2]')
        comment_field.clear()
        print("   ✅ Đã xóa Nội dung")
    except Exception as e:
        print(f"   ⚠️ Không xóa được Nội dung: {e}")
        success = False
    
    time.sleep(0.5)
    
    if success:
        print("   ⚠️ Đã xóa text, nhưng ảnh và địa điểm có thể vẫn còn")
    
    return success


def reset_checkin_with_fallback(driver, navigate_to_checkin_func):
    """
    ⭐ SMART: Thử reset bằng back, nếu fail thì dùng clear text.
    
    Args:
        driver: Appium WebDriver instance
        navigate_to_checkin_func: Hàm để mở lại Check-in
    
    Returns:
        True nếu reset thành công (bằng cách nào đó)
    """
    # Thử cách 1: Back & reopen (tốt nhất)
    if reset_checkin_by_back_and_reopen(driver, navigate_to_checkin_func):
        return True
    
    # Cách 2: Fallback - Clear text only
    print("   🔄 Fallback: Dùng clear text thủ công...")
    return clear_text_fields_only(driver)


def verify_checkin_screen_clean(driver):
    """
    Kiểm tra form Check-in có sạch không.
    
    Returns:
        True nếu form sạch (title và comment rỗng)
    """
    try:
        title_field = driver.find_element(AppiumBy.XPATH, '//android.widget.EditText[1]')
        comment_field = driver.find_element(AppiumBy.XPATH, '//android.widget.EditText[2]')
        
        title_text = title_field.text or ""
        comment_text = comment_field.text or ""
        
        is_clean = (len(title_text.strip()) == 0 and len(comment_text.strip()) == 0)
        
        if is_clean:
            print("   ✅ Form Check-in text fields đã sạch")
        else:
            print(f"   ⚠️ Form vẫn có dữ liệu: title='{title_text}', comment='{comment_text}'")
        
        return is_clean
    except Exception as e:
        print(f"   ⚠️ Không kiểm tra được: {e}")
        return False


def reset_checkin_screen_by_navigate(driver, navigate_to_checkin_func):
    """
    Reset form bằng cách THOÁT RA và VÀO LẠI màn hình Check-in.
    
    Cách này chắc chắn form sẽ trống hoàn toàn.
    
    Args:
        driver: Appium WebDriver instance
        navigate_to_checkin_func: Hàm để mở màn hình Check-in
                                   (ví dụ: click FAB → chọn Blog)
    """
    print("   🔄 Reset form bằng cách thoát ra và vào lại...")
    
    # 1. Thoát màn hình Check-in (Back button)
    try:
        # Tìm nút Back trong AppBar
        back_btn = driver.find_element(
            AppiumBy.XPATH,
            '//android.widget.ImageButton[@content-desc="Back" or @content-desc="Navigate up"]'
        )
        back_btn.click()
        print("   ✅ Đã thoát màn hình Check-in")
    except:
        # Fallback: Dùng hardware back button
        driver.back()
        print("   ✅ Đã nhấn nút Back (hardware)")
    
    time.sleep(1)
    
    # 2. Gọi lại hàm navigate để mở Check-in screen
    print("   🔄 Đang mở lại màn hình Check-in...")
    navigate_to_checkin_func(driver)
    time.sleep(2)
    
    print("   ✅ Đã reset form thành công")


def clear_specific_field(driver, field_type):
    """
    Xóa một field cụ thể.
    
    Args:
        driver: Appium WebDriver instance
        field_type: 'title', 'comment', 'image', 'place'
    """
    if field_type == 'title':
        try:
            title_field = driver.find_element(AppiumBy.XPATH, '//android.widget.EditText[1]')
            title_field.clear()
            print("   ✅ Đã xóa Tiêu đề")
            return True
        except:
            print("   ❌ Không xóa được Tiêu đề")
            return False
    
    elif field_type == 'comment':
        try:
            comment_field = driver.find_element(AppiumBy.XPATH, '//android.widget.EditText[2]')
            comment_field.clear()
            print("   ✅ Đã xóa Nội dung")
            return True
        except:
            print("   ❌ Không xóa được Nội dung")
            return False
    
    elif field_type == 'image':
        # Xóa tất cả ảnh
        try:
            remove_btns = driver.find_elements(
                AppiumBy.XPATH,
                '//*[contains(@content-desc, "remove") or contains(@content-desc, "xóa")]'
            )
            for btn in remove_btns:
                btn.click()
                time.sleep(0.2)
            print(f"   ✅ Đã xóa {len(remove_btns)} ảnh")
            return True
        except:
            print("   ❌ Không xóa được ảnh")
            return False
    
    elif field_type == 'place':
        # Xóa địa điểm
        try:
            clear_place_btn = driver.find_element(
                AppiumBy.XPATH,
                '//*[contains(@content-desc, "clear") or contains(@content-desc, "xóa địa điểm")]'
            )
            clear_place_btn.click()
            print("   ✅ Đã xóa địa điểm")
            return True
        except:
            print("   ❌ Không xóa được địa điểm")
            return False
    
    return False