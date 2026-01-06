from appium import webdriver
from appium.webdriver.common.appiumby import AppiumBy
from appium.options.android import UiAutomator2Options
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
import time
import subprocess

# --- IMPORT FLOWS & HELPERS ---
from flows.add_image_flow import add_image_flow
from flows.pick_place_flow import add_place_flow
from flows.submit_flow import submit_full_logic
from helpers.snackbar import expect_validation_error, expect_snackbar_sequence
from helpers.clear_form import reset_checkin_by_back_and_reopen, verify_checkin_screen_clean

# --- CONFIG ---
APPIUM_SERVER_URL = "http://localhost:4723"
APP_PACKAGE = "com.example.nhom_3_damh_lttbdd"
APP_ACTIVITY = "com.example.nhom_3_damh_lttbdd.MainActivity"

def adb_input_text(text):
    """Dùng ADB để nhập text cho Flutter"""
    text = text.replace(' ', '%s')
    subprocess.run(f'adb shell input text "{text}"', shell=True)
    time.sleep(0.3)

def find_element_flexible(driver, name, strategies, timeout=15):
    """Tìm element với nhiều strategy"""
    print(f"[DEBUG] Đang tìm: {name}")
    for by, loc in strategies:
        try:
            el = WebDriverWait(driver, timeout).until(
                EC.presence_of_element_located((by, loc))
            )
            if el.is_displayed():
                print(f"   ✅ Tìm thấy {name} bằng {by}")
                return el
        except:
            continue
    raise Exception(f"❌ Không tìm thấy {name}")

def safe_input_text(driver, xpath, text):
    """Nhập text an toàn với retry"""
    try:
        field = driver.find_element(AppiumBy.XPATH, xpath)
        field.click()
        time.sleep(0.3)
        adb_input_text(text)
        try:
            driver.hide_keyboard()
        except:
            subprocess.run('adb shell input keyevent 4', shell=True)
        return True
    except Exception as e:
        print(f"   ⚠️ Lỗi nhập text: {e}")
        return False

def navigate_to_checkin(driver):
    """Mở màn hình Check-in từ Explore"""
    wait = WebDriverWait(driver, 20)
    
    print("   📍 Navigate đến Check-in screen...")
    
    # Click Tab Khám phá
    explore_tab = wait.until(EC.element_to_be_clickable(
        (AppiumBy.ACCESSIBILITY_ID, "Khám phá")
    ))
    explore_tab.click()
    time.sleep(2)
    
    # Click FAB
    fab = wait.until(EC.element_to_be_clickable(
        (AppiumBy.ACCESSIBILITY_ID, "CreatePostFAB")
    ))
    fab.click()
    time.sleep(2)
    
    # Chọn Blog option
    blog_option = wait.until(EC.element_to_be_clickable((
        AppiumBy.ACCESSIBILITY_ID, 
        "create_post_blog_option\nBlog\nViết bài"
    )))
    blog_option.click()
    time.sleep(3)
    
    print("   ✅ Đã mở màn hình Check-in")

def scroll_to_submit_button(driver):
    """Scroll xuống để thấy nút Đăng bài"""
    driver.execute_script('mobile: scrollGesture', {
        'left': 200, 'top': 500, 'width': 600, 'height': 800,
        'direction': 'down', 'percent': 2.0
    })
    time.sleep(0.5)

def click_submit_button(driver, wait):
    """Click nút Đăng bài"""
    scroll_to_submit_button(driver)
    
    submit_btn = wait.until(EC.element_to_be_clickable((
        AppiumBy.XPATH, 
        '//*[contains(@content-desc, "Đăng bài") or contains(@text, "Đăng bài")]'
    )))
    submit_btn.click()
    print("   🚀 Đã click nút Đăng bài")
    time.sleep(2)

def run_test():
    print("=" * 70)
    print("🧪 AUTOMATED TEST SUITE: CHECK-IN VALIDATION")
    print("=" * 70)

    desired_caps = {
        "platformName": "Android",
        "automationName": "UiAutomator2",
        "deviceName": "emulator-5554",
        "appPackage": APP_PACKAGE,
        "appActivity": APP_ACTIVITY,
        "noReset": False,
        "autoGrantPermissions": True,
        "newCommandTimeout": 600,
    }

    options = UiAutomator2Options().load_capabilities(desired_caps)
    driver = webdriver.Remote(command_executor=APPIUM_SERVER_URL, options=options)
    driver.implicitly_wait(3)
    wait = WebDriverWait(driver, 20)

    try:
        # ========================================
        # 🔐 BƯỚC LOGIN (Một lần duy nhất)
        # ========================================
        print("\n[SETUP] Đăng nhập vào ứng dụng...")
        time.sleep(8)  # Chờ splash
        
        email_el = driver.find_element(
            AppiumBy.XPATH, 
            '//android.widget.EditText[contains(@hint,"Email")]'
        )
        password_el = driver.find_element(
            AppiumBy.XPATH, 
            '//android.widget.EditText[contains(@hint,"mật khẩu")]'
        )
        
        email_el.click()
        adb_input_text("kha123@gmail.com")
        driver.hide_keyboard()
        
        password_el.click()
        adb_input_text("123456")
        driver.hide_keyboard()

        driver.find_element(AppiumBy.ACCESSIBILITY_ID, "login_button").click()
        print("   ✅ Đã login thành công")
        time.sleep(5)

        # Navigate đến Check-in screen lần đầu
        navigate_to_checkin(driver)

        # ========================================
        # 📊 BIẾN ĐẾM KẾT QUẢ
        # ========================================
        total_tests = 0
        passed_tests = 0
        failed_tests = 0

        # ========================================
        # TEST CASE 1: Bỏ trống tất cả (ảnh, title, comment, place)
        # ========================================
        total_tests += 1
        print("\n" + "="*70)
        print(f"[TEST CASE {total_tests}] ❌ Validation: Bỏ trống tất cả các trường")
        print("="*70)
        
        click_submit_button(driver, wait)
        
        if expect_validation_error(driver, 'image'):
            print("   ✅ PASSED: Báo lỗi thiếu ảnh (lỗi ưu tiên cao nhất)")
            passed_tests += 1
        else:
            print("   ❌ FAILED: Không thấy lỗi thiếu ảnh")
            failed_tests += 1
        
        reset_checkin_by_back_and_reopen(driver, navigate_to_checkin)
        verify_checkin_screen_clean(driver)

        # ========================================
        # TEST CASE 2: Chỉ điền Tiêu đề
        # ========================================
        total_tests += 1
        print("\n" + "="*70)
        print(f"[TEST CASE {total_tests}] ❌ Validation: Chỉ có tiêu đề")
        print("="*70)
        
        safe_input_text(driver, '//android.widget.EditText[1]', "Tieu%sde%schi%sduoc%snhap")
        click_submit_button(driver, wait)
        
        if expect_validation_error(driver, 'image'):
            print("   ✅ PASSED: Vẫn báo thiếu ảnh")
            passed_tests += 1
        else:
            print("   ❌ FAILED")
            failed_tests += 1
        
        reset_checkin_by_back_and_reopen(driver, navigate_to_checkin)
        verify_checkin_screen_clean(driver)

        # ========================================
        # TEST CASE 3: Chỉ điền Nội dung chia sẻ
        # ========================================
        total_tests += 1
        print("\n" + "="*70)
        print(f"[TEST CASE {total_tests}] ❌ Validation: Chỉ có nội dung chia sẻ")
        print("="*70)
        
        safe_input_text(driver, '//android.widget.EditText[2]', "Noi%sdung%schia%sse%srat%shay")
        click_submit_button(driver, wait)
        
        if expect_validation_error(driver, 'image'):
            print("   ✅ PASSED: Vẫn báo thiếu ảnh")
            passed_tests += 1
        else:
            print("   ❌ FAILED")
            failed_tests += 1
        
        reset_checkin_by_back_and_reopen(driver, navigate_to_checkin)
        verify_checkin_screen_clean(driver)

        # ========================================
        # TEST CASE 4: Chỉ chọn Địa điểm
        # ========================================
        total_tests += 1
        print("\n" + "="*70)
        print(f"[TEST CASE {total_tests}] ❌ Validation: Chỉ chọn địa điểm")
        print("="*70)
        
        if add_place_flow(driver, wait):
            click_submit_button(driver, wait)
            if expect_validation_error(driver, 'image'):
                print("   ✅ PASSED: Báo thiếu ảnh dù đã có địa điểm")
                passed_tests += 1
            else:
                print("   ❌ FAILED")
                failed_tests += 1
        else:
            print("   ⚠️ SKIPPED: Không chọn được địa điểm")
            failed_tests += 1
        
        reset_checkin_by_back_and_reopen(driver, navigate_to_checkin)
        verify_checkin_screen_clean(driver)

        # ========================================
        # TEST CASE 5: Chỉ thêm Ảnh
        # ========================================
        total_tests += 1
        print("\n" + "="*70)
        print(f"[TEST CASE {total_tests}] ❌ Validation: Chỉ có ảnh")
        print("="*70)
        
        if add_image_flow(driver, find_element_flexible):
            click_submit_button(driver, wait)
            if expect_validation_error(driver, 'title'):
                print("   ✅ PASSED: Báo lỗi thiếu tiêu đề (sau khi đã có ảnh)")
                passed_tests += 1
            else:
                print("   ❌ FAILED: Không báo lỗi thiếu tiêu đề")
                failed_tests += 1
        else:
            print("   ⚠️ SKIPPED: Không thêm được ảnh")
            failed_tests += 1
        
        reset_checkin_by_back_and_reopen(driver, navigate_to_checkin)
        verify_checkin_screen_clean(driver)

        # ========================================
        # TEST CASE 6: Có ảnh + title → Thiếu comment và place
        # ========================================
        total_tests += 1
        print("\n" + "="*70)
        print(f"[TEST CASE {total_tests}] ❌ Validation: Có ảnh + tiêu đề (thiếu nội dung & địa điểm)")
        print("="*70)
        
        if add_image_flow(driver, find_element_flexible):
            safe_input_text(driver, '//android.widget.EditText[1]', "Co%stieu%sde%sva%sanh")
            click_submit_button(driver, wait)
            if expect_validation_error(driver, 'comment'):
                print("   ✅ PASSED: Báo lỗi thiếu nội dung chia sẻ")
                passed_tests += 1
            else:
                print("   ❌ FAILED")
                failed_tests += 1
        else:
            print("   ⚠️ SKIPPED")
            failed_tests += 1
        
        reset_checkin_by_back_and_reopen(driver, navigate_to_checkin)
        verify_checkin_screen_clean(driver)

        # ========================================
        # TEST CASE 7: Có ảnh + title + comment → Thiếu địa điểm
        # ========================================
        total_tests += 1
        print("\n" + "="*70)
        print(f"[TEST CASE {total_tests}] ❌ Validation: Thiếu địa điểm (các trường khác đã đủ)")
        print("="*70)
        
        if add_image_flow(driver, find_element_flexible):
            safe_input_text(driver, '//android.widget.EditText[1]', "Day%sdu%sanh%svatitle")
            safe_input_text(driver, '//android.widget.EditText[2]', "Noi%sdung%schia%sse")
            click_submit_button(driver, wait)
            if expect_validation_error(driver, 'place'):
                print("   ✅ PASSED: Báo lỗi thiếu địa điểm")
                passed_tests += 1
            else:
                print("   ❌ FAILED")
                failed_tests += 1
        else:
            print("   ⚠️ SKIPPED")
            failed_tests += 1
        
        reset_checkin_by_back_and_reopen(driver, navigate_to_checkin)
        verify_checkin_screen_clean(driver)

        # ========================================
        # TEST CASE 8: Có ảnh + comment + place → Thiếu tiêu đề
        # ========================================
        total_tests += 1
        print("\n" + "="*70)
        print(f"[TEST CASE {total_tests}] ❌ Validation: Thiếu tiêu đề (các trường khác đã có)")
        print("="*70)
        
        if add_image_flow(driver, find_element_flexible) and add_place_flow(driver, wait):
            safe_input_text(driver, '//android.widget.EditText[2]', "Chi%sco%snoi%sdung")
            click_submit_button(driver, wait)
            if expect_validation_error(driver, 'title'):
                print("   ✅ PASSED: Báo lỗi thiếu tiêu đề")
                passed_tests += 1
            else:
                print("   ❌ FAILED")
                failed_tests += 1
        else:
            print("   ⚠️ SKIPPED: Không thêm được ảnh hoặc địa điểm")
            failed_tests += 1
        
        reset_checkin_by_back_and_reopen(driver, navigate_to_checkin)
        verify_checkin_screen_clean(driver)

        # ========================================
        # TEST CASE 9: Có ảnh + title + place → Thiếu nội dung chia sẻ
        # ========================================
        total_tests += 1
        print("\n" + "="*70)
        print(f"[TEST CASE {total_tests}] ❌ Validation: Thiếu nội dung chia sẻ")
        print("="*70)
        
        if add_image_flow(driver, find_element_flexible) and add_place_flow(driver, wait):
            safe_input_text(driver, '//android.widget.EditText[1]', "Co%stieu%sde%svadiadiem")
            click_submit_button(driver, wait)
            if expect_validation_error(driver, 'comment'):
                print("   ✅ PASSED: Báo lỗi thiếu nội dung")
                passed_tests += 1
            else:
                print("   ❌ FAILED")
                failed_tests += 1
        else:
            print("   ⚠️ SKIPPED")
            failed_tests += 1
        
        reset_checkin_by_back_and_reopen(driver, navigate_to_checkin)
        verify_checkin_screen_clean(driver)

        # ========================================
        # TEST CASE 10: Happy Path - Đăng bài thành công
        # ========================================
        total_tests += 1
        print("\n" + "="*70)
        print(f"[TEST CASE {total_tests}] ✅ Happy Path: Đăng bài thành công")
        print("="*70)

        happy_path_success = True

        # 1. Thêm ảnh
        if not add_image_flow(driver, find_element_flexible):
            print("   ❌ FAILED: Không thêm được ảnh")
            happy_path_success = False
            failed_tests += 1
        else:
            print("   ✅ Thêm ảnh thành công")
            safe_input_text(driver, '//android.widget.EditText[1]', "AutoTest%sChuyen%sDi%sDa%sLat")
            safe_input_text(driver, '//android.widget.EditText[2]', "Noi%sdung%sauto%stest%sreview%shomestay")

            # 2. Chọn địa điểm
            if not add_place_flow(driver, wait):
                print("   ❌ FAILED: Không chọn được địa điểm")
                happy_path_success = False
                failed_tests += 1
            else:
                print("   ✅ Chọn địa điểm thành công")
                
                # 3. Submit
                click_submit_button(driver, wait)
                print("   ⏳ Đang chờ quay về ExploreScreen (tối đa 25s)...")

                # === CHỈ TÌM FAB 1 LẦN DUY NHẤT ĐỂ XÁC NHẬN ===
                try:
                    # DÙNG CHÍNH XÁC LOCATOR ĐÃ CLICK THÀNH CÔNG TRƯỚC ĐÓ
                    explore_fab = WebDriverWait(driver, 25).until(
                        EC.presence_of_element_located(
                            (AppiumBy.ACCESSIBILITY_ID, "CreatePostFAB")
                        )
                    )
                    
                    # Kiểm tra displayed để chắc chắn
                    if explore_fab.is_displayed():
                        print("   🎉 PASSED: Đăng bài THÀNH CÔNG HOÀN TOÀN!")
                        print("      ✅ Flow đầy đủ: Ảnh + Title + Comment + Place + Submit")
                        print("      ✅ Đã quay về ExploreScreen (thấy FAB 'CreatePostFAB')")
                        passed_tests += 1
                    else:
                        print("   ⚠️ FAB tồn tại nhưng không hiển thị")
                        happy_path_success = False
                        failed_tests += 1
                        
                except Exception as e:
                    print("   ❌ FAILED: Không tìm thấy FAB sau khi submit!")
                    print(f"      Lỗi: {str(e)[:200]}...")  # Truncate lỗi dài
                    driver.save_screenshot(f"happy_path_fail_no_fab_{int(time.time())}.png")
                    print("   📸 Đã chụp screenshot debug")
                    happy_path_success = False
                    failed_tests += 1

        print(f"   📊 Test Case 10: {'✅ PASSED' if happy_path_success else '❌ FAILED'}")

        # ========================================
        # 📊 TỔNG KẾT
        # ========================================
        print("\n" + "="*70)
        print("📊 KẾT QUẢ TEST")
        print("="*70)
        print(f"   Tổng số test:  {total_tests}")
        print(f"   ✅ Passed:     {passed_tests}")
        print(f"   ❌ Failed:     {failed_tests}")
        print(f"   📈 Tỷ lệ:      {(passed_tests / total_tests * 100):.1f}%")
        print("="*70)

        if failed_tests == 0:
            print("🎉 TẤT CẢ TEST CASES ĐỀU PASSED!")
        else:
            print(f"⚠️ CÓ {failed_tests} TEST CASES FAILED. Cần kiểm tra lại!")

    except Exception as e:
        print(f"\n❌ LỖI HỆ THỐNG: {e}")
        import traceback
        traceback.print_exc()
        try:
            driver.save_screenshot(f"error_main_test_{int(time.time())}.png")
        except:
            pass
    
    finally:
        try:
            driver.quit()
            print("\n🏁 Đã đóng driver")
        except:
            pass
if __name__ == "__main__":
    run_test()