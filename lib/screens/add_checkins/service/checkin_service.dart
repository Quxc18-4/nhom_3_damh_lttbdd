// File: screens/checkin/service/checkin_service.dart

import 'dart:io'; // Import `dart:io` để dùng kiểu `File` (cần thiết cho việc upload)
import 'package:flutter/foundation.dart'; // Import `foundation` để dùng `debugPrint` (in ra console trong chế độ debug)
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore để truy vấn
import 'package:image_picker/image_picker.dart'; // Import để dùng `ImagePicker` và `XFile`
import 'package:nhom_3_damh_lttbdd/services/cloudinary_service.dart'; // Import service upload ảnh
import 'package:geolocator/geolocator.dart'; // Import để lấy vị trí GPS
import 'package:geocoding/geocoding.dart'; // Import để chuyển đổi (latitude, longitude) sang tên Tỉnh/Thành
import 'package:nhom_3_damh_lttbdd/constants/cityExchange.dart'; // Import file chứa hàm map tên tỉnh -> ID tỉnh

// Định nghĩa lớp Service
class CheckinService {
  // `final` vì các đối tượng này được khởi tạo 1 lần và không bao giờ thay đổi.

  // `_firestore`: Biến instance để tương tác với Cloud Firestore.
  final _firestore = FirebaseFirestore.instance;

  // `_cloudinaryService`: Biến instance để gọi các hàm upload.
  final _cloudinaryService = CloudinaryService();

  // `_picker`: Biến instance để gọi các hàm chọn ảnh/chụp ảnh.
  final _picker = ImagePicker();

  /// Tải chi tiết một địa điểm từ Firestore bằng ID
  // `Future<DocumentSnapshot>`: Hàm `async` này sẽ trả về một `DocumentSnapshot` trong tương lai.
  Future<DocumentSnapshot> fetchPlaceDetails(String placeId) async {
    try {
      // `await`: Chờ cho Firestore thực hiện xong lệnh `get()`.
      // `collection('places').doc(placeId)`: Truy cập vào tài liệu
      // có ID là `placeId` bên trong bộ sưu tập `places`.
      final placeDoc = await _firestore.collection('places').doc(placeId).get();

      // Kiểm tra xem tài liệu có thực sự tồn tại không.
      if (!placeDoc.exists) {
        // Nếu không, `throw Exception` (ném ra một lỗi).
        // Lỗi này sẽ được bắt (catch) bởi `_CheckinScreenState`.
        throw Exception('Không tìm thấy thông tin địa điểm ($placeId).');
      }

      // Trả về tài liệu đã tìm thấy.
      return placeDoc;
    } catch (e) {
      debugPrint("Lỗi tải chi tiết địa điểm: $e");
      rethrow; // `rethrow` (ném lại) lỗi để lớp UI (CheckinScreen) có thể bắt và xử lý
    }
  }

  /// Tải tất cả địa điểm cho Mini Map Picker
  // `Future<List<DocumentSnapshot>>`: Trả về một *danh sách* các tài liệu.
  Future<List<DocumentSnapshot>> fetchAllPlaces() async {
    try {
      // `.get()` trên một `collection` sẽ trả về một `QuerySnapshot`.
      QuerySnapshot snapshot = await _firestore.collection('places').get();
      // `snapshot.docs` là một `List<DocumentSnapshot>` chứa tất cả tài liệu.
      return snapshot.docs;
    } catch (e) {
      debugPrint("Lỗi tải places cho map picker: $e");
      rethrow;
    }
  }

  /// Tải 1 ảnh lên Cloudinary
  // `Future<String?>`: Trả về URL (dạng `String`) của ảnh đã upload,
  // hoặc `null` nếu có lỗi (mặc dù ở đây bạn đang `rethrow` lỗi).
  Future<String?> uploadLocalFile(XFile imageFile) async {
    // `image_picker` trả về `XFile`. Dịch vụ upload (và `dart:io`) cần `File`.
    // Chúng ta chuyển đổi bằng cách lấy `imageFile.path` (đường dẫn file).
    // `File`: Là kiểu dữ liệu chuẩn của Dart để đại diện cho một file trong hệ thống.
    File file = File(imageFile.path);
    try {
      // Gọi service khác để thực hiện upload.
      return await _cloudinaryService.uploadImageToCloudinary(file);
    } catch (e) {
      debugPrint("Lỗi tải ảnh '${imageFile.name}' lên Cloudinary: $e");
      rethrow;
    }
  }

  /// Gửi bài review (logic chính)
  Future<void> submitReview({
    // Sử dụng `required` cho tất cả các tham số
    required String userId,
    required DocumentSnapshot selectedPlaceDoc,
    required String title,
    required String comment,
    required List<String> hashtags,
    required List<XFile> selectedImages,
  }) async {
    try {
      // === BƯỚC 1: UPLOAD ẢNH ===

      // `List<String>`: Đây sẽ là danh sách các URL (dạng text) của ảnh
      // sau khi upload thành công, để lưu vào Firestore.
      List<String> finalImageUrls = [];

      if (selectedImages.isNotEmpty) {
        // **Xử lý song song (Parallel Processing):**
        // 1. `.map(uploadLocalFile)`: Biến `List<XFile>` thành
        //    `List<Future<String?>>`. Đây là một danh sách các *tác vụ upload
        //    chưa được thực thi* (hoặc đang thực thi).
        List<Future<String?>> uploadFutures = selectedImages
            .map(uploadLocalFile)
            .toList();

        // 2. `await Future.wait(uploadFutures)`:
        //    - `Future.wait`: Chờ cho **tất cả** các `Future` (các tác vụ upload)
        //      trong danh sách `uploadFutures` hoàn thành.
        //    - Các tác vụ này chạy *song song*, giúp tiết kiệm thời gian
        //      hơn là `await` từng ảnh một trong vòng lặp `for`.
        //    - `results`: Sẽ là một `List<String?>`, ví dụ:
        //      ['url1.jpg', 'url2.jpg', null, 'url4.jpg'] (nếu ảnh 3 bị lỗi).
        List<String?> results = await Future.wait(uploadFutures);

        // 3. `.whereType<String>()`: Lọc danh sách, chỉ giữ lại các
        //    phần tử có kiểu là `String` (tức là không `null`).
        //    -> `['url1.jpg', 'url2.jpg', 'url4.jpg']`
        finalImageUrls = results.whereType<String>().toList();

        // Nếu không có ảnh nào được upload thành công (ví dụ: mất mạng)
        if (finalImageUrls.isEmpty) {
          throw Exception(
            'Không thể tải lên bất kỳ ảnh nào. Vui lòng thử lại.',
          );
        }
      }

      // Lấy dữ liệu từ `DocumentSnapshot` và ép kiểu (cast) về `Map`.
      // `as Map<String, dynamic>? ?? {}`:
      // 1. `as Map<String, dynamic>?`: Ép kiểu data về Map (có thể null).
      // 2. `?? {}`: Nếu data là `null` (hiếm khi), sử dụng một Map rỗng.
      final placeData = selectedPlaceDoc.data() as Map<String, dynamic>? ?? {};

      // Lấy danh sách categoryIds từ địa điểm.
      // `as List<dynamic>? ?? []`:
      // 1. `as List<dynamic>?`: Ép kiểu về List (có thể null). `dynamic` vì
      //    Firestore có thể trả về `List<String>`, `List<int>`, v.v.
      // 2. `?? []`: Nếu không có trường 'categories' (null), dùng list rỗng.
      final List<dynamic> categoryIds =
          placeData['categories'] as List<dynamic>? ?? [];

      // === BƯỚC 2: CHUẨN BỊ DỮ LIỆU FIRESTORE ===

      // Tham chiếu đến collection 'reviews'.
      final reviewsCollection = _firestore.collection('reviews');

      // `reviewsCollection.doc()`:
      // Gọi `.doc()` mà không truyền ID sẽ yêu cầu Firestore *tự động
      // tạo ra một ID duy nhất* (unique ID) cho tài liệu mới.
      // `newDoc` lúc này là một `DocumentReference`.
      final newDoc = reviewsCollection.doc();

      // `Map<String, dynamic>`: Đây là kiểu dữ liệu chuẩn để ghi (set)
      // dữ liệu lên Firestore.
      // - `String`: Tên của trường (field name).
      // - `dynamic`: Giá trị của trường (có thể là String, int, List, bool,
      //   Timestamp, GeoPoint, Map...).
      final reviewData = {
        'userId': userId,
        'placeId': selectedPlaceDoc.id, // Lấy ID của địa điểm
        'rating': 5, // Tạm thời (hardcode)
        'comment': comment,
        'title': title,
        'imageUrls': finalImageUrls, // Lưu danh sách URL đã upload
        'hashtags': hashtags,
        // `FieldValue.serverTimestamp()`:
        // Yêu cầu server Firestore sử dụng *đồng hồ của chính nó* để
        // ghi dấu thời gian.
        // **Tại sao?** Đồng hồ trên thiết bị của người dùng (client) có thể
        // bị sai (do sai múi giờ, hoặc người dùng tự chỉnh). Dùng
        // `serverTimestamp` đảm bảo tính toàn vẹn và thứ tự dữ liệu.
        'createdAt': FieldValue.serverTimestamp(),
        'likeCount': 0, // Khởi tạo các giá trị đếm
        'commentCount': 0,
        'categoryIds':
            categoryIds, // Lưu lại category của địa điểm để tiện truy vấn sau này
      };

      // === BƯỚC 3: GHI VÀO FIRESTORE ===
      // `await newDoc.set(reviewData)`: Ghi dữ liệu `reviewData` vào
      // tài liệu (document) đã được tạo ở trên.
      await newDoc.set(reviewData);

      // === BƯỚC 4: CẬP NHẬT 'places' ===
      // Sau khi tạo review thành công, cập nhật `reviewCount` của địa điểm.
      await _firestore.collection('places').doc(selectedPlaceDoc.id).update({
        // `FieldValue.increment(1)`:
        // Một thao tác *nguyên tử* (atomic) của Firestore.
        // **Tại sao?** Nếu dùng `currentCount + 1` (read-then-write),
        // có thể xảy ra "race condition" (nếu 2 người cùng review 1 lúc).
        // `increment(1)` đảm bảo server Firestore sẽ tự cộng 1 vào giá trị
        // hiện tại một cách an toàn.
        'reviewCount': FieldValue.increment(1),
      });

      // === BƯỚC 5: CẬP NHẬT TỈNH THÀNH (FIRE-AND-FORGET) ===
      // "Fire-and-forget" (Bắn và Quên):
      // Chúng ta gọi hàm `updateVisitedProvinceOnCheckin` nhưng **không `await`** nó.
      // **Tại sao?**
      // 1. Đây là một tác vụ "thêm" (bonus), không quan trọng bằng việc đăng review.
      // 2. Nó có thể mất thời gian (gọi GPS, Geocoding) hoặc thất bại (người dùng
      //    tắt GPS, không cấp quyền).
      // 3. Chúng ta muốn `submitReview` kết thúc nhanh chóng và báo "Thành công"
      //    cho người dùng, mà không cần chờ tác vụ này.
      // Nó sẽ tự chạy ngầm (in the background).
      updateVisitedProvinceOnCheckin(userId);
    } catch (e) {
      debugPrint("Lỗi khi gửi review: $e");
      rethrow; // Ném lỗi về cho `CheckinScreen` để hiển thị SnackBar
    }
  }

  /// Cập nhật tỉnh thành đã ghé thăm (lấy từ GPS)
  Future<void> updateVisitedProvinceOnCheckin(String userId) async {
    // Đây là một tác vụ chạy ngầm, nên `try/catch` toàn bộ để
    // nó không bao giờ ném lỗi ra ngoài và làm crash app (vì không có ai
    // `await` và `catch` nó ở bên ngoài).
    try {
      // 1. Kiểm tra xem người dùng có bật dịch vụ vị trí không.
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint("VisitedProvince: Dịch vụ vị trí đã tắt.");
        return; // Dừng lại
      }

      // 2. Kiểm tra quyền truy cập vị trí.
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        debugPrint("VisitedProvince: Quyền vị trí bị từ chối.");
        return; // Dừng lại
      }

      // 3. Lấy vị trí hiện tại.
      // `LocationAccuracy.medium`: Độ chính xác trung bình (cân bằng giữa
      // tốc độ và độ chính xác, tiết kiệm pin hơn `high`).
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );

      // 4. Chuyển đổi (latitude, longitude) sang địa chỉ (Geocoding).
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isEmpty) {
        debugPrint("VisitedProvince: Không thể geocode vị trí hiện tại.");
        return;
      }

      // `administrativeArea` thường là tên Tỉnh/Thành phố.
      // Ví dụ: "Hồ Chí Minh", "Hanoi", "Ba Ria - Vung Tau Province".
      // `?? ''`: Nếu null, dùng chuỗi rỗng.
      String rawCityName = placemarks.first.administrativeArea ?? '';

      // 5. Chuẩn hóa tên Tỉnh/Thành.
      // GPS/Geocoding trả về tên không đồng nhất (ví dụ: "Hồ Chí Minh", "Ho Chi Minh City",...).
      // Hàm `getMergedProvinceIdFromGeolocator` (từ file `cityExchange.dart`)
      // có nhiệm vụ map tên này về một ID chuẩn (ví dụ: 'tphcm').
      String? provinceId = getMergedProvinceIdFromGeolocator(rawCityName);

      if (provinceId == null) {
        debugPrint(
          "VisitedProvince: Không thể map '$rawCityName' sang ID chuẩn.",
        );
        return;
      }

      // 6. Cập nhật vào Firestore.
      await _firestore.collection('users').doc(userId).update({
        // `FieldValue.arrayUnion([provinceId])`:
        // Một thao tác nguyên tử khác.
        // Nó sẽ thêm `provinceId` vào mảng `visitedProverbs` *CHỈ KHI*
        // `provinceId` đó chưa tồn tại trong mảng.
        // **Tại sao?** Để đảm bảo mảng không bị trùng lặp (ví dụ:
        // không bị `['tphcm', 'hanoi', 'tphcm']`).
        'visitedProverbs': FieldValue.arrayUnion([provinceId]),
      });

      debugPrint("VisitedProvince: Đã cập nhật thành công: $provinceId");
    } catch (e) {
      // Bắt tất cả lỗi (ví dụ: mất mạng khi đang update,...)
      debugPrint("VisitedProvince: Lỗi không xác định: $e");
    }
  }

  // === LOGIC IMAGE PICKER ===

  /// Chọn nhiều ảnh từ Thư viện
  // `int currentCount`: Số ảnh đã chọn.
  // `int max`: Giới hạn tối đa.
  Future<List<XFile>> pickImagesFromGallery(int currentCount, int max) async {
    // Tính toán số lượng ảnh còn lại có thể chọn.
    int availableSlots = max - currentCount;
    if (availableSlots <= 0) return []; // Nếu đã đủ, trả về list rỗng

    // `pickMultiImage()`: Mở thư viện và cho phép chọn nhiều ảnh.
    final List<XFile> images = await _picker.pickMultiImage();

    // Giới hạn số lượng ảnh được thêm vào.
    // Ví dụ: `availableSlots` = 3, nhưng người dùng chọn 5 ảnh (`images.length` = 5).
    // `countToAdd` = 3.
    int countToAdd = images.length < availableSlots
        ? images.length
        : availableSlots;

    // `sublist(0, countToAdd)`: Chỉ lấy 3 ảnh đầu tiên trong số 5 ảnh đã chọn.
    return images.sublist(0, countToAdd);
  }

  /// Chụp ảnh từ Camera
  Future<XFile?> pickImageFromCamera(int currentCount, int max) async {
    if (currentCount >= max) return null; // Nếu đã đủ, không cho chụp

    // `pickImage(source: ImageSource.camera)`: Mở camera.
    // Trả về `XFile?` (nullable) vì người dùng có thể mở camera rồi... hủy.
    return await _picker.pickImage(source: ImageSource.camera);
  }
}
