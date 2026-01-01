import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:latlong2/latlong.dart';
import 'package:image_picker/image_picker.dart';

// --- CÁC IMPORT CỦA BẠN ---
import 'package:nhom_3_damh_lttbdd/screens/add_places/service/add_place_service.dart';
import 'package:nhom_3_damh_lttbdd/screens/add_places/addPlaceRequest.dart';
import 'package:nhom_3_damh_lttbdd/model/category_model.dart';
import 'package:nhom_3_damh_lttbdd/constants/cityExchange.dart';

// Import file mock
@GenerateMocks([AddPlaceService])
import 'add_place_screen_test.mocks.dart';

void main() {
  late MockAddPlaceService mockService;

  // ====================================================
  // 1. DỮ LIỆU MẪU (MOCK DATA)
  // Đây là dữ liệu giả để test, không cần lấy từ server thật
  // ====================================================
  final mockCategory = CategoryModel(id: 'cat1', name: 'Cafe Test');
  final mockLatLng = LatLng(10.762622, 106.660172);
  final String validCityName = kProvinceDisplayNames['ho_chi_minh']!;

  // Địa chỉ giả nhưng hợp lệ (đầy đủ thông tin)
  final mockAddressValid = FetchedAddress(
    street: '123 Đường Test',
    ward: 'Phường Test',
    city: validCityName,
    rawCity: 'Ho Chi Minh City',
  );

  setUp(() {
    mockService = MockAddPlaceService();

    // --- CẤU HÌNH HÀNH VI GIẢ (STUBBING) ---
    // Khi màn hình gọi fetchCategories -> Trả về danh sách giả ngay lập tức
    when(mockService.fetchCategories()).thenAnswer((_) async => [mockCategory]);
    // Khi màn hình gọi fetchAddressDetails -> Trả về địa chỉ giả ngay lập tức
    when(
      mockService.fetchAddressDetails(any),
    ).thenAnswer((_) async => mockAddressValid);
  });

  Future<void> pumpScreen(WidgetTester tester) async {
    // Kéo dài màn hình ảo (2400px) để chắc chắn nút bấm hiện ra (tránh lỗi không tìm thấy nút)
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AddPlaceScreen(
            initialLatLng: mockLatLng,
            userId: 'test_user_id',
            service: mockService,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle(); // Chờ giao diện vẽ xong
  }

  group('Kiểm thử Whitebox: 5 Đường dẫn cơ sở', () {
    final submitButtonFinder = find.widgetWithText(
      ElevatedButton,
      'GỬI YÊU CẦU',
    );

    // === WB1: Lỗi Validation (Tên rỗng) ===
    testWidgets('WB1 (Path 1): Hiển thị lỗi Validation khi tên rỗng', (
      WidgetTester tester,
    ) async {
      await pumpScreen(tester);

      // Hành động: Bấm nút Gửi ngay khi chưa nhập gì
      await tester.ensureVisible(submitButtonFinder);
      await tester.tap(submitButtonFinder);
      await tester.pump();

      // ==========================================
      // CHECK FAIL/PASS: Tìm dòng chữ báo lỗi
      // Nếu tìm thấy 1 widget chứa chữ này -> PASS
      // ==========================================
      expect(find.text('Vui lòng nhập tên địa điểm'), findsOneWidget);
    });

    // === WB2: Lỗi Logic (Chưa chọn danh mục) ===
    testWidgets('WB2 (Path 2): Hiển thị SnackBar khi chưa chọn danh mục', (
      WidgetTester tester,
    ) async {
      await pumpScreen(tester);
      // Nhập tên để vượt qua WB1
      await tester.enterText(
        find.byType(TextFormField).first,
        'Quán Cafe Test',
      );

      await tester.ensureVisible(submitButtonFinder);
      await tester.tap(submitButtonFinder);
      await tester.pump();

      // ==========================================
      // CHECK FAIL/PASS: Tìm SnackBar báo lỗi
      // ==========================================
      expect(find.text('Vui lòng chọn ít nhất một danh mục.'), findsOneWidget);
    });

    // === WB3: Chặn Spam (Loading) ===
    testWidgets('WB3 (Path 3): Nút chuyển sang Loading khi đang gửi', (
      WidgetTester tester,
    ) async {
      // Setup giả: Hàm submit sẽ bị "treo" 2 giây (giả vờ mạng chậm)
      when(
        mockService.submitPlaceRequest(
          userId: anyNamed('userId'),
          latLng: anyNamed('latLng'),
          name: anyNamed('name'),
          notes: anyNamed('notes'),
          street: anyNamed('street'),
          ward: anyNamed('ward'),
          city: anyNamed('city'),
          selectedCategories: anyNamed('selectedCategories'),
          selectedImages: anyNamed('selectedImages'),
        ),
      ).thenAnswer((_) async {
        await Future.delayed(const Duration(seconds: 2));
      });

      await pumpScreen(tester);
      await tester.enterText(
        find.byType(TextFormField).first,
        'Quán Cafe Test',
      );

      // Chọn danh mục
      final addButton = find.text('Thêm');
      await tester.ensureVisible(addButton);
      await tester.tap(addButton);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cafe Test'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(submitButtonFinder);
      await tester.tap(submitButtonFinder);

      await tester.pump(); // Chỉ render 1 khung hình, không chờ hết 2 giây

      // ==========================================
      // CHECK FAIL/PASS: Tìm vòng xoay Loading
      // Nếu nút Gửi biến mất và thay bằng vòng xoay -> PASS
      // ==========================================
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pump(
        const Duration(seconds: 2),
      ); // Chờ cho hết 2 giây giả lập
    });

    // === WB4: Thành công (Happy Path) ===
    testWidgets('WB4 (Path 4): Gửi thành công -> Đóng màn hình', (
      WidgetTester tester,
    ) async {
      // Setup giả: Hàm submit trả về thành công (Future void)
      when(
        mockService.submitPlaceRequest(
          userId: anyNamed('userId'),
          latLng: anyNamed('latLng'),
          name: anyNamed('name'),
          notes: anyNamed('notes'),
          street: anyNamed('street'),
          ward: anyNamed('ward'),
          city: anyNamed('city'),
          selectedCategories: anyNamed('selectedCategories'),
          selectedImages: anyNamed('selectedImages'),
        ),
      ).thenAnswer((_) async => Future.value());

      await pumpScreen(tester);

      // Điền đủ thông tin
      await tester.enterText(
        find.byType(TextFormField).first,
        'Quán Cafe Test',
      );
      final addButton = find.text('Thêm');
      await tester.ensureVisible(addButton);
      await tester.tap(addButton);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cafe Test'));
      await tester.pumpAndSettle();

      // Bấm Gửi
      await tester.ensureVisible(submitButtonFinder);
      await tester.tap(submitButtonFinder);

      await tester
          .pumpAndSettle(); // Chờ mọi hiệu ứng hoàn tất (bao gồm đóng màn hình)

      // ==========================================
      // CHECK FAIL/PASS: Kiểm tra màn hình đã đóng
      // Nếu KHÔNG TÌM THẤY tiêu đề "Thông tin địa điểm" nữa -> PASS (vì đã pop)
      // ==========================================
      expect(find.text('Thông tin địa điểm'), findsNothing);
    });

    // === WB5: Lỗi API (Có vòng lặp chờ) ===
    testWidgets('WB5 (Path 5): Gửi thất bại do lỗi API', (
      WidgetTester tester,
    ) async {
      // Setup giả: Hàm submit ném ra lỗi (Exception)
      when(
        mockService.submitPlaceRequest(
          userId: anyNamed('userId'),
          latLng: anyNamed('latLng'),
          name: anyNamed('name'),
          notes: anyNamed('notes'),
          street: anyNamed('street'),
          ward: anyNamed('ward'),
          city: anyNamed('city'),
          selectedCategories: anyNamed('selectedCategories'),
          selectedImages: anyNamed('selectedImages'),
        ),
      ).thenThrow(Exception('Lỗi mạng kết nối'));

      await pumpScreen(tester);

      // Điền đủ thông tin
      await tester.enterText(
        find.byType(TextFormField).first,
        'Quán Cafe Test',
      );
      final addButton = find.text('Thêm');
      await tester.ensureVisible(addButton);
      await tester.tap(addButton);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cafe Test'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(submitButtonFinder);
      await tester.tap(submitButtonFinder);

      // Chờ SnackBar đầu tiên "Đang xử lý..." hiện ra
      await tester.pump();

      // --- KỸ THUẬT POLLING (VÒNG LẶP KIỂM TRA) ---
      // Vì SnackBar lỗi chỉ hiện sau khi cái "Đang xử lý" biến mất (khoảng 4s),
      // ta dùng vòng lặp để chờ.
      bool found = false;
      for (int i = 0; i < 20; i++) {
        await tester.pump(
          const Duration(milliseconds: 500),
        ); // Tua nhanh 0.5s mỗi lần

        // Kiểm tra xem chữ "Lỗi mạng" đã hiện chưa
        if (find.textContaining('Lỗi mạng kết nối').evaluate().isNotEmpty) {
          found = true;
          break; // Thấy rồi thì thoát ngay
        }
      }

      // ==========================================
      // CHECK FAIL/PASS:
      // 1. Phải tìm thấy (found == true)
      // 2. Widget đó phải đang hiển thị
      // ==========================================
      expect(
        found,
        isTrue,
        reason: "Không tìm thấy thông báo lỗi sau khi chờ đợi",
      );
      expect(find.textContaining('Lỗi mạng kết nối'), findsOneWidget);
    });
  });
}
