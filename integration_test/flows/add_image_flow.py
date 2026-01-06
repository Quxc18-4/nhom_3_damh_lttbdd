import time
from appium.webdriver.common.appiumby import AppiumBy

def add_image_flow(driver, find_element_flexible):
    """
    Thêm ảnh từ Gallery - GIỮ NGUYÊN 100% LOGIC GỐC
    """
    print("   📷 Thêm ảnh từ hệ thống...")
    
    try:
        # ✅ BƯỚC 1: Click nút "Thêm ảnh" chính trên Form
        add_image_btn = find_element_flexible(
            driver, 
            "Add Image Button",
            [
                (AppiumBy.ACCESSIBILITY_ID, "Thêm ảnh/bài viết (tối đa 10)"),  # ⚠️ FILE CŨ THIẾU
                (AppiumBy.XPATH, '//*[contains(@content-desc,"Thêm ảnh")]'),
                (AppiumBy.ACCESSIBILITY_ID, "btn_pick_image"),
            ],
            timeout=10  # ⚠️ FILE CŨ DÙNG 15, GỐC LÀ 10
        )
        add_image_btn.click()
        print("   ✅ Click nút Thêm ảnh chính")
        time.sleep(1.5)  # ⚠️ FILE CŨ DÙNG 2s, GỐC LÀ 1.5s

        # ✅ BƯỚC 2: Click "Chọn từ thư viện" trên BottomSheet
        gallery_option = find_element_flexible(
            driver,
            "Gallery Option",
            [
                (AppiumBy.ACCESSIBILITY_ID, "btn_pick_gallery"),
                (AppiumBy.XPATH, '//*[contains(@text,"Chọn từ thư viện")]'),
                (AppiumBy.XPATH, '//*[contains(@content-desc,"Chọn từ thư viện")]'),
            ],
            timeout=5  # ⚠️ FILE CŨ DÙNG 10, GỐC LÀ 5
        )
        gallery_option.click()
        print("   ✅ Đã chọn 'Thư viện' từ Dialog")
        time.sleep(3)  # Chờ hệ thống Android Picker mở ra

        # ✅ BƯỚC 3: Chọn ảnh đầu tiên trong Android Photo Picker
        print("   📸 Đang tìm ảnh trong Photo Picker (Compose View)...")
        
        # ⚠️ FILE CŨ THIẾU strategy thứ 3 (ANDROID_UIAUTOMATOR)
        image_strategies = [
            (AppiumBy.XPATH, '//android.view.View[contains(@content-desc, "Photo taken on")]'),
            (AppiumBy.XPATH, '//com.google.android.photopicker//android.view.View[@clickable="true"]'),
            (AppiumBy.ANDROID_UIAUTOMATOR, 'new UiSelector().className("android.view.View").packageName("com.google.android.photopicker").clickable(true)')  # ⚠️ THIẾU
        ]

        first_image = None
        for strategy_type, locator in image_strategies:
            try:
                elements = driver.find_elements(strategy_type, locator)
                if elements:
                    first_image = elements[0]
                    print(f"   ✅ Tìm thấy ảnh bằng chiến thuật: {strategy_type}")  # ⚠️ THIẾU
                    break
            except:
                continue

        if not first_image:
            # Cách dự phòng: Click theo tọa độ
            print("   ⚠️ Không tìm thấy element, thử click theo tọa độ ước tính...")  # ⚠️ THIẾU
            driver.tap([(179, 1411)])
        else:
            first_image.click()
            print("   ✅ Đã click chọn ảnh đầu tiên thành công")  # ⚠️ THIẾU "thành công"
        
        time.sleep(2)

        # ✅ BƯỚC 4: Click vào nút "Done"
        print("   🎯 Đang tìm nút 'Done' để hoàn tất...")
        
        # ⚠️ FILE CŨ CHỈ DÙNG TỌA ĐỘ → SAI, PHẢI THỬ TÌM ELEMENT TRƯỚC
        done_strategies = [
            (AppiumBy.XPATH, '//android.widget.Button[.//android.widget.TextView[@text="Done"]]'),
            (AppiumBy.XPATH, '//*[@text="Done"]'),
            (AppiumBy.XPATH, '//android.widget.Button[@package="com.google.android.photopicker"]'),
            (AppiumBy.ANDROID_UIAUTOMATOR, 'new UiSelector().className("android.widget.Button").packageName("com.google.android.photopicker").instance(0)')
        ]

        done_btn_clicked = False
        for s_type, s_locator in done_strategies:
            try:
                btn = driver.find_element(s_type, s_locator)
                if btn:
                    btn.click()
                    done_btn_clicked = True
                    print(f"   ✅ Đã nhấn 'Done' bằng {s_type}")
                    break
            except:
                continue

        # Nếu không tìm thấy element, dùng tọa độ
        if not done_btn_clicked:
            print("   ⚠️ Không tìm thấy nút Done, click theo tọa độ [907, 2162]...")
            driver.tap([(907, 2162)])
            done_btn_clicked = True

        print("   🎉 Thêm ảnh và xác nhận thành công!")
        time.sleep(3)
        return True
        
    except Exception as e:
        print(f"   ⚠️ Lỗi tại bước chọn ảnh/Done: {e}")
        driver.save_screenshot("error_photopicker_done.png")  # ⚠️ FILE CŨ THIẾU
        return False