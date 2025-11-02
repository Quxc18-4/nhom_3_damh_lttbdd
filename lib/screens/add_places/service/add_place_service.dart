// File: screens/add_places/service/add_place_service.dart

import 'dart:io'; // Import 'dart:io' để sử dụng lớp 'File'. Cần thiết cho việc upload
import 'package:flutter/foundation.dart'; // Import 'foundation' để dùng 'debugPrint' (in log)
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore, cần cho 'GeoPoint' và 'FieldValue'
import 'package:geocoding/geocoding.dart'; // Import thư viện 'geocoding' để chuyển đổi LatLng -> Địa chỉ
import 'package:image_picker/image_picker.dart'; // Import 'image_picker' để nhận kiểu 'XFile' từ UI
import 'package:latlong2/latlong.dart'; // Import 'latlong2' để nhận kiểu 'LatLng' từ UI
import 'package:nhom_3_damh_lttbdd/constants/cityExchange.dart'; // Import các hàm/biến chuẩn hóa tên Tỉnh/Thành
import 'package:nhom_3_damh_lttbdd/model/category_model.dart'; // Import model Category
import 'package:nhom_3_damh_lttbdd/services/cloudinary_service.dart'; // Import service upload ảnh

/// Kết quả trả về từ hàm fetchAddressDetails
///
/// **Tại sao dùng class `FetchedAddress` mà không phải `Map`?**
/// 1. **An toàn kiểu (Type Safety):** Dùng class, trình biên dịch sẽ báo lỗi
///    ngay nếu bạn gõ sai tên (ví dụ: `result.strete` thay vì `result.street`).
///    Nếu dùng Map (`result['strete']`), nó sẽ trả về `null` và gây lỗi
///    lúc chạy (runtime error) rất khó tìm.
/// 2. **Rõ ràng (Clarity):** Nhìn vào định nghĩa class là biết
///    chính xác hàm này trả về những gì, kiểu dữ liệu nào, cái nào
///    có thể `null`.
class FetchedAddress {
  final String street; // Tên đường (không null)
  final String ward; // Tên Phường/Xã/Quận (không null)
  final String?
  city; // Tên thành phố ĐÃ CHUẨN HÓA (có thể null nếu geocoding không khớp)
  final String? rawCity; // Tên thành phố GỐC từ geocoding (để debug)

  FetchedAddress({
    required this.street,
    required this.ward,
    this.city,
    this.rawCity,
  });
}

// Lớp dịch vụ
class AddPlaceService {
  // `final`: Các instance dịch vụ này được tạo 1 lần và không bao giờ thay đổi
  final _firestore = FirebaseFirestore.instance; // Instance để gọi Firestore
  final _cloudinaryService = CloudinaryService(); // Instance để gọi Cloudinary

  /// Tải danh sách tất cả Category
  // `Future<List<CategoryModel>>`: Hàm này `async` và sẽ trả về
  // một danh sách (List) các đối tượng (Object) kiểu `CategoryModel`.
  Future<List<CategoryModel>> fetchCategories() async {
    try {
      // 1. Lấy tất cả tài liệu từ collection 'categories'
      final snapshot = await _firestore.collection('categories').get();
      // 2. `snapshot.docs` là một List<DocumentSnapshot>
      final categories = snapshot.docs
          .map(
            (doc) => CategoryModel.fromFirestore(doc),
          ) // 3. Dùng factory `fromFirestore` trong
          //    model để biến từng `doc`
          //    (dữ liệu Map) thành một
          //    đối tượng `CategoryModel`
          .toList(); // 4. Chuyển kết quả `map` thành một `List`

      // 5. Sắp xếp list theo tên (a -> z)
      categories.sort((a, b) => a.name.compareTo(b.name));
      return categories;
    } catch (e) {
      debugPrint("Lỗi fetch categories: $e");
      rethrow; // Ném lỗi ra ngoài để UI (State) bắt và hiển thị SnackBar
    }
  }

  /// Lấy chi tiết địa chỉ từ tọa độ LatLng
  // `Future<FetchedAddress>`: Hàm `async`, trả về đối tượng
  // `FetchedAddress` mà chúng ta đã định nghĩa ở trên.
  Future<FetchedAddress> fetchAddressDetails(LatLng latLng) async {
    try {
      // 1. Gọi API của 'geocoding' để lấy địa chỉ từ tọa độ
      List<Placemark> placemarks = await placemarkFromCoordinates(
        latLng.latitude,
        latLng.longitude,
      );

      if (placemarks.isNotEmpty) {
        // 2. Lấy kết quả đầu tiên (thường là chính xác nhất)
        final Placemark place = placemarks.first;

        // 3. Trích xuất thông tin. `geocoding` trả về tên rất "thô".
        // `thoroughfare` thường là Tên đường
        // `subAdministrativeArea` thường là Phường/Xã hoặc Quận/Huyện
        // `administrativeArea` thường là Tỉnh/Thành
        // `?? 'Không xác định'`: Toán tử Null-coalescing.
        // Nếu `place.thoroughfare` là `null`, nó sẽ gán
        // giá trị `'Không xác định'`. Điều này giúp UI không
        // bao giờ nhận giá trị `null` và bị crash.
        String street = place.thoroughfare ?? 'Không xác định';
        String ward = place.subAdministrativeArea ?? 'Không xác định';
        String rawPlacemarkCity = place.administrativeArea ?? '';

        // 4. **Luồng chuẩn hóa Tỉnh/Thành (Rất quan trọng):**
        // 'geocoding' có thể trả về "Hanoi", "Hà Nội", "Hanoi City".
        // Chúng ta cần chuẩn hóa nó.

        // a. Lấy ID chuẩn (ví dụ: 'hanoi')
        String? mergedProvinceId = getMergedProvinceIdFromGeolocator(
          rawPlacemarkCity,
        );

        String? selectedCity; // Tên hiển thị chuẩn (ví dụ: 'Thành phố Hà Nội')
        if (mergedProvinceId != null) {
          // b. Nếu có ID, lấy tên hiển thị chuẩn
          selectedCity = formatProvinceIdToName(mergedProvinceId);
        } else {
          // c. Nếu không thể khớp ID, báo log
          debugPrint(
            "Không thể khớp '$rawPlacemarkCity' với bất kỳ ID tỉnh/thành nào.",
          );
        }

        // 5. Trả về đối tượng `FetchedAddress` đã được xử lý
        return FetchedAddress(
          street: street,
          ward: ward,
          city: selectedCity, // Trả về tên ĐÃ CHUẨN HÓA (có thể null)
          rawCity: rawPlacemarkCity, // Trả về tên GỐC
        );
      } else {
        throw Exception('Không thể tìm thấy thông tin địa chỉ cho tọa độ này.');
      }
    } catch (e) {
      debugPrint("Lỗi geocoding: $e");
      rethrow;
    }
  }

  /// Tải 1 file ảnh lên Cloudinary
  // `_` (gạch dưới) ở đầu tên: Hàm này là `private`, chỉ
  // được gọi bởi các hàm khác bên trong file `add_place_service.dart`
  // (cụ thể là `submitPlaceRequest`).
  // `Future<String?>`: Trả về URL (String) nếu thành công,
  // hoặc `null` nếu thất bại.
  Future<String?> _uploadLocalFile(XFile imageFile) async {
    // 1. `image_picker` trả về `XFile`. Dịch vụ upload cần `File`.
    // Chúng ta chuyển đổi bằng cách `File(imageFile.path)`.
    File file = File(imageFile.path);
    try {
      // 2. Gọi service upload
      String? uploadedUrl = await _cloudinaryService.uploadImageToCloudinary(
        file,
      );
      return uploadedUrl;
    } catch (e) {
      debugPrint("Lỗi tải ảnh '${imageFile.name}' lên Cloudinary: $e");
      // **Tại sao `return null` mà không `rethrow`?**
      // Vì ở hàm `submitPlaceRequest`, chúng ta dùng `Future.wait` để
      // upload nhiều ảnh song song. Nếu 1 ảnh lỗi và `rethrow`,
      // `Future.wait` sẽ dừng lại và báo lỗi ngay lập tức.
      // Bằng cách `return null`, chúng ta cho phép `Future.wait`
      // tiếp tục chạy. Sau đó, chúng ta chỉ cần lọc bỏ
      // các kết quả `null` là được. Đây là cách xử lý lỗi
      // "bán phần" (partial failure) rất hiệu quả.
      return null; // Trả về null nếu lỗi
    }
  }

  /// Gửi toàn bộ form đăng ký địa điểm
  Future<void> submitPlaceRequest({
    required String userId,
    required LatLng latLng,
    required String name,
    required String notes,
    required String street,
    required String ward,
    required String city,
    required List<CategoryModel> selectedCategories,
    required List<XFile> selectedImages,
  }) async {
    try {
      // --- BƯỚC 1: UPLOAD ẢNH (XỬ LÝ SONG SONG) ---
      List<String> uploadedImageUrls = [];
      if (selectedImages.isNotEmpty) {
        // a. Tạo 1 list các "Nhiệm vụ" (Future)
        List<Future<String?>> uploadFutures = [];
        for (XFile imageFile in selectedImages) {
          // Thêm "nhiệm vụ" vào list (chưa chạy)
          uploadFutures.add(_uploadLocalFile(imageFile));
        }

        // b. `Future.wait`: Ra lệnh "Hãy chạy tất cả các nhiệm vụ
        //    này CÙNG MỘT LÚC (song song) và chờ cho đến khi
        //    TẤT CẢ hoàn thành".
        // `results` sẽ là một `List<String?>`, ví dụ: ['url1', null, 'url2']
        List<String?> results = await Future.wait(uploadFutures);

        // c. Lọc bỏ các kết quả `null` (ảnh bị lỗi)
        uploadedImageUrls = results
            .whereType<String>() // Chỉ giữ lại các phần tử là 'String'
            .toList();

        // d. Kiểm tra: Nếu người dùng có chọn ảnh, nhưng TẤT CẢ đều
        //    upload lỗi -> báo lỗi
        if (uploadedImageUrls.isEmpty && selectedImages.isNotEmpty) {
          throw Exception('Không thể tải lên bất kỳ ảnh nào.');
        }
      }

      // --- BƯỚC 2: CHUẨN BỊ DỮ LIỆU FIRESTORE ---
      final String fullAddress = '$street, $ward, $city';

      // `selectedCategories` là `List<CategoryModel>` (list các đối tượng).
      // Firestore không cần lưu cả object (tốn dung lượng, dư thừa).
      // Chúng ta chỉ cần lưu ID của chúng.
      // `.map((cat) => cat.id)`: Biến `List<CategoryModel>`
      // thành `List<String>` (chỉ chứa ID).
      // Đây là cách lưu dữ liệu quan hệ (relationship) hiệu quả.
      final List<String> categoryIds = selectedCategories
          .map((cat) => cat.id)
          .toList();

      // `Map<String, dynamic>`: Cấu trúc chuẩn bị để
      // ghi lên Firestore. Key là `String`, Value là `dynamic`
      // (vì có thể là String, List, GeoPoint, Timestamp...).
      final Map<String, dynamic> submissionData = {
        'submittedBy': userId,
        'status': 'pending', // Trạng thái: Chờ duyệt
        'submittedAt': FieldValue.serverTimestamp(), // Dùng giờ của server
        // **Tại sao có `placeData` lồng bên trong?**
        // Đây là một cấu trúc rất hay. Dữ liệu này nằm trong
        // collection `placeSubmissions` (yêu cầu chờ duyệt).
        // Khi admin duyệt, họ chỉ cần 1 cloud function copy
        // nguyên cái `placeData` này sang collection `places`
        // là xong. Cấu trúc dữ liệu được đồng bộ hoàn hảo.
        'placeData': {
          'name': name,
          'description': notes, // Mô tả ban đầu (từ ghi chú)
          'location': {
            // **Tại sao dùng `GeoPoint`?**
            // Đây là kiểu dữ liệu *đặc biệt* của Firestore.
            // Bằng cách lưu tọa độ dưới dạng `GeoPoint`, chúng ta
            // có thể thực hiện các truy vấn phức tạp như
            // "Tìm tất cả địa điểm trong bán kính 5km quanh tôi".
            // Nếu lưu `lat` và `lng` thành 2 số (double) riêng biệt,
            // bạn sẽ không thể làm được việc này.
            'coordinates': GeoPoint(latLng.latitude, latLng.longitude),
            'fullAddress': fullAddress,
            'street': street,
            'ward': ward,
            'city': city,
          },
          'categories': categoryIds, // `List<String>`
          'images': uploadedImageUrls, // `List<String>`
          'ratingAverage': 0, // Khởi tạo các giá trị
          'reviewCount': 0,
          'createdAt': FieldValue.serverTimestamp(),
          'createdBy': userId,
        },
        'initialReviewData':
            {}, // Có thể để dành cho tính năng "ghi chú thành review đầu tiên"
      };

      // --- BƯỚC 3: GỬI LÊN FIRESTORE ---
      // `collection('placeSubmissions').add(...)`:
      // Dùng `.add()` khi bạn muốn Firestore *tự động tạo ID
      // tài liệu* (document ID) cho bạn.
      await _firestore.collection('placeSubmissions').add(submissionData);
    } catch (e) {
      debugPrint("Lỗi khi gửi submission: $e");
      rethrow; // Ném lỗi ra để UI xử lý
    }
  }
}
