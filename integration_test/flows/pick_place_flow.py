import time
from appium.webdriver.common.appiumby import AppiumBy
from selenium.webdriver.support import expected_conditions as EC

def add_place_flow(driver, wait):
    """
    Chọn địa điểm - GIỮ NGUYÊN 100% LOGIC GỐC
    """
    print("   📍 Chọn địa điểm (GÁN CỐ ĐỊNH MÌ CAY SASIN)...")
    
    try:
        # 1. Mở Map Picker (Nút có icon bản đồ hoặc text "Chọn địa điểm")
        try:
            # Tìm nút dựa trên Semantics label đã đặt trong Flutter
            place_picker_btn = wait.until(EC.element_to_be_clickable((
                AppiumBy.ACCESSIBILITY_ID, "btn_pick_place"
            )))
            place_picker_btn.click()
        except:
            # Fallback: Click vào vị trí dòng chữ "Chọn địa điểm từ bản đồ"
            driver.find_element(AppiumBy.XPATH, "//*[contains(@content-desc, 'địa điểm')]").click()
        
        print("   ✅ Đã mở Map Picker")
        time.sleep(4)  # Chờ danh sách địa điểm load từ API/Firebase

        # 2. Chọn chính xác "Mì cay sasin"
        print("   🎯 Đang tìm địa điểm: Mì cay sasin...")
        
        # Chiến thuật XPATH: Tìm Button có content-desc chứa chữ "Mì cay sasin"
        # Cách này an toàn hơn vì nó bỏ qua phần địa chỉ loằng ngoằng phía sau
        sasin_xpath = '//android.widget.Button[contains(@content-desc, "Mì cay sasin")]'
        
        try:
            sasin_item = wait.until(EC.element_to_be_clickable((AppiumBy.XPATH, sasin_xpath)))
            sasin_item.click()
            print("   ✅ Đã chọn: Mì cay sasin Nguyễn Gia Trí")
        except Exception as e:
            print(f"   ⚠️ Không tìm thấy Mì cay sasin: {e}")
            # Dự phòng: Nếu không tìm thấy theo tên, chọn đại mục đầu tiên trong danh sách
            print("   ℹ️ Thử chọn mục đầu tiên làm dự phòng...")
            first_item = driver.find_element(AppiumBy.XPATH, '//android.view.View/android.widget.Button[1]')
            first_item.click()

        time.sleep(2)  # Chờ quay lại màn hình Check-in
        return True
        
    except Exception as e:
        print(f"   ⚠️ Lỗi chọn địa điểm: {e}")
        # ⚠️ NÊN THÊM SCREENSHOT KHI LỖI (tùy chọn, nhưng tốt hơn)
        # driver.save_screenshot("error_pick_place.png")
        return False