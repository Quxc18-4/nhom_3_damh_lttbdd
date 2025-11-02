// File: screens/checkin/checkin_screen.dart

import 'package:flutter/material.dart'; // Import thư viện Material của Flutter để sử dụng các UI components (Widget)
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore để làm việc với kiểu dữ liệu 'DocumentSnapshot' (lưu địa điểm đã chọn)
import 'package:image_picker/image_picker.dart'; // Import image_picker để làm việc với kiểu 'ImageSource' (camera/gallery) và 'XFile' (file ảnh)
import 'dart:io'; // Import dart:io để làm việc với 'File', mặc dù trong file này bạn chưa dùng trực tiếp (nhưng checkin_widgets có dùng)

// Import Service và Widgets đã tách
import 'service/checkin_service.dart'; // Import file service chứa logic nghiệp vụ (tải dữ liệu, upload ảnh...)
import 'widget/checkin_widgets.dart'; // Import file chứa các Widget con đã được tách ra cho sạch sẽ
import 'widget/mini_map_picker.dart'; // Import file chứa Widget chọn địa điểm trên bản đồ

// Màu sắc (lấy từ file gốc)
// Khai báo `const` (hằng số) vì giá trị này được biết tại thời điểm biên dịch (compile-time).
// Kiểu `Color` là một class đặc biệt của Flutter, lưu giá trị màu ARGB (Alpha, Red, Green, Blue).
// 0xFFE4C99E:
// - 0xFF: Alpha = 255 (không trong suốt)
// - E4C99E: Mã màu Hex
const Color kAppbarColor = Color(0xFFE4C99E);

// Lớp CheckinScreen là một StatefulWidget.
// Chọn `StatefulWidget` vì màn hình này cần thay đổi nội dung dựa trên tương tác của người dùng
// (ví dụ: danh sách ảnh thay đổi, địa điểm được chọn thay đổi, trạng thái loading/saving...).
class CheckinScreen extends StatefulWidget {
  // `final` vì các thuộc tính (properties) của một Widget luôn là bất biến (immutable).
  // Nếu muốn thay đổi, chúng ta phải tạo một Widget mới (thường do State thực hiện).

  // `String` là kiểu dữ liệu phù hợp nhất để lưu ID.
  final String currentUserId;

  // `String?` (kiểu String có thể null - nullable):
  // Vì màn hình này có thể được mở theo 2 cách:
  // 1. Mở từ một địa điểm cụ thể (có initialPlaceId)
  // 2. Mở tự do, không có địa điểm ban đầu (initialPlaceId = null)
  final String? initialPlaceId;

  // Constructor của Widget
  const CheckinScreen({
    super.key, // `key` giúp Flutter nhận diện và quản lý các Widget trong cây (widget tree)
    required this.currentUserId, // `required` đảm bảo ID người dùng phải được truyền vào
    this.initialPlaceId, // Không có `required` vì nó là nullable, có thể không cần truyền
  });

  @override
  // Hàm này tạo ra đối tượng State (bộ não) liên kết với Widget này.
  State<CheckinScreen> createState() => _CheckinScreenState();
}

// Lớp `_CheckinScreenState` là nơi chứa toàn bộ trạng thái và logic của `CheckinScreen`.
// Chữ `_` (gạch dưới) ở đầu tên lớp có nghĩa là lớp này là `private`, chỉ có thể truy cập
// bên trong file `checkin_screen.dart` này.
class _CheckinScreenState extends State<CheckinScreen> {
  // === KHAI BÁO BIẾN TRẠNG THÁI (STATE) VÀ CONTROLLER ===

  // Service
  // `final` vì bản thân đối tượng `CheckinService` không bao giờ thay đổi.
  // Chúng ta chỉ gọi các phương thức bên trong nó.
  final CheckinService _service = CheckinService();

  // Controllers
  // `TextEditingController` là một class đặc biệt để "điều khiển" một TextField.
  // Nó cho phép chúng ta:
  // 1. Đọc nội dung (lấy text) người dùng đã nhập.
  // 2. Thay đổi nội dung (ví dụ: `_hashtagController.clear()`).
  // 3. Lắng nghe sự thay đổi (nhưng bạn không dùng ở đây).
  // Chúng là `final` vì đối tượng controller không thay đổi, chỉ có nội dung (thuộc tính `text`) bên trong nó thay đổi.
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();
  final TextEditingController _hashtagController = TextEditingController();

  // State (Các biến trạng thái)

  // `DocumentSnapshot?` (nullable):
  // - `DocumentSnapshot`: Là kiểu dữ liệu chuẩn của Firestore, đại diện cho một tài liệu (document)
  //   cụ thể (trong trường hợp này là document của địa điểm). Nó chứa cả data và metadata.
  // - `?` (nullable): Vì ban đầu, người dùng chưa chọn địa điểm nào (`_selectedPlaceDoc` sẽ là `null`).
  DocumentSnapshot? _selectedPlaceDoc;

  // `bool`: Kiểu dữ liệu luận lý (true/false) đơn giản.
  // Dùng để hiển thị một `CircularProgressIndicator` (xoay xoay) trong khi đang
  // tải thông tin địa điểm (khi có `initialPlaceId`).
  bool _isLoadingPlace = false;

  // `List<XFile>`:
  // - `List`: Chúng ta cần lưu nhiều ảnh.
  // - `XFile`: Đây là kiểu dữ liệu trả về của thư viện `image_picker`. Nó là một
  //   "đối tượng đại diện" (wrapper) cho file đã chọn, giúp xử lý đa nền tảng (mobile, web).
  // Khởi tạo là `[]` (một danh sách rỗng) thay vì `null` để tránh lỗi "Null check" khi
  // ta gọi `.length` hoặc `.add` sau này.
  List<XFile> _selectedImages = [];

  // `List<String>`: Lưu danh sách các hashtag (dạng text).
  // Khởi tạo với 2 giá trị mặc định.
  List<String> _hashtags = ['#travelmap', '#checkin'];

  // `List<String>`: Lưu danh sách các hashtag gợi ý (để hiển thị cho người dùng).
  // `final` vì danh sách gợi ý này không thay đổi trong suốt vòng đời của State.
  final List<String> _suggestedTags = [
    '#review',
    '#foodie',
    '#amazingvietnam',
    '#phuquoc',
  ];

  // `bool`: Dùng để kiểm soát nút "Đăng bài".
  // Khi `_isSaving` là `true`, chúng ta sẽ:
  // 1. Vô hiệu hóa nút "Đăng bài" (ngăn người dùng bấm 2 lần).
  // 2. Hiển thị một `CircularProgressIndicator` trên nút.
  bool _isSaving = false;

  // `final int`: Dùng `int` (số nguyên) để lưu giới hạn số ảnh.
  // `final` vì con số này là cố định.
  final int _maxImages = 10;

  @override
  // `initState` là hàm được gọi **một lần duy nhất** khi State này được tạo ra
  // (trước khi `build` được gọi lần đầu).
  // Đây là nơi hoàn hảo để khởi tạo dữ liệu ban đầu.
  void initState() {
    super.initState(); // Luôn gọi `super.initState()` đầu tiên

    // **Luồng hoạt động khi khởi tạo (Initialization Flow):**
    // 1. Kiểm tra xem `widget.initialPlaceId` (truyền từ bên ngoài vào) có tồn tại và không rỗng không.
    //    `widget.` là cách để truy cập các thuộc tính của `CheckinScreen` (lớp Widget) từ
    //    bên trong `_CheckinScreenState` (lớp State).
    if (widget.initialPlaceId != null && widget.initialPlaceId!.isNotEmpty) {
      // 2. Nếu có, gọi hàm `_handleFetchPlaceDetails` để tải thông tin
      //    chi tiết của địa điểm đó ngay lập tức.
      //    Sử dụng `!` (null assertion operator) vì chúng ta đã kiểm tra `!= null` ở trên.
      _handleFetchPlaceDetails(widget.initialPlaceId!);
    }
  }

  @override
  // `dispose` là hàm được gọi khi State này bị hủy vĩnh viễn (ví dụ: khi
  // người dùng bấm "Back" để thoát khỏi màn hình này).
  // Đây là nơi để "dọn dẹp" tài nguyên.
  void dispose() {
    // **Quan trọng:** Phải `dispose()` các `TextEditingController`.
    // Nếu không, chúng sẽ vẫn tồn tại trong bộ nhớ, gây ra rò rỉ bộ nhớ (memory leak).
    _titleController.dispose();
    _commentController.dispose();
    _hashtagController.dispose();
    super.dispose(); // Gọi `super.dispose()` ở cuối cùng
  }

  // === HÀM XỬ LÝ LOGIC (GỌI SERVICE) ===

  // Một hàm tiện ích (utility function) để hiển thị SnackBar.
  void _showSnackBar(String message, {bool isError = false}) {
    // **Kiểm tra `mounted` (RẤT QUAN TRỌNG):**
    // `mounted` là một thuộc tính `bool` của State.
    // - `true`: Widget vẫn đang tồn tại trên cây widget (vẫn đang hiển thị).
    // - `false`: Widget đã bị `dispose` (ví dụ: người dùng đã thoát khỏi màn hình).
    // Khi gọi các hàm `async` (như `_handleSubmitReview`), có khả năng người dùng
    // đã thoát màn hình *trước khi* hàm `async` hoàn thành.
    // Nếu chúng ta cố gắng sử dụng `context` (như `ScaffoldMessenger.of(context)`)
    // khi `mounted` là `false`, app sẽ bị crash.
    // Do đó, luôn luôn kiểm tra `if (mounted)` trước khi thao tác với `context`
    // sau một lời gọi `await`.
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError
              ? Colors.redAccent
              : null, // Hiển thị màu đỏ nếu là lỗi
        ),
      );
    }
  }

  /// Tải chi tiết địa điểm (gọi service)
  // `Future<void>`: Hàm này là `async` (bất đồng bộ) và không trả về giá trị gì (`void`).
  Future<void> _handleFetchPlaceDetails(String placeId) async {
    if (!mounted) return; // Kiểm tra `mounted` ngay đầu hàm

    // **Luồng hoạt động (setState):**
    // 1. Gọi `setState` để cập nhật `_isLoadingPlace = true`.
    //    -> Flutter sẽ `build` lại UI, hiển thị một `CircularProgressIndicator`
    //       (logic này nằm trong `PlaceSection` widget).
    setState(() => _isLoadingPlace = true);

    // Sử dụng `try/catch/finally` để xử lý lỗi một cách an toàn.
    try {
      // `await`: Tạm dừng hàm `_handleFetchPlaceDetails` tại đây,
      // cho đến khi `_service.fetchPlaceDetails(placeId)` hoàn thành
      // và trả về kết quả (hoặc ném ra lỗi).
      final placeDoc = await _service.fetchPlaceDetails(placeId);

      // Sau khi `await` hoàn thành, kiểm tra `mounted` một lần nữa.
      if (mounted) {
        // 2. Gọi `setState` lần 2 để lưu kết quả vào `_selectedPlaceDoc`.
        //    -> Flutter sẽ `build` lại UI, hiển thị thông tin địa điểm
        //       (logic này nằm trong `PlaceSection` widget).
        setState(() {
          _selectedPlaceDoc = placeDoc;
        });
      }
    } catch (e) {
      // 3. Nếu `await` ném ra lỗi (Exception), nó sẽ được bắt (catch) ở đây.
      if (mounted) {
        // Hiển thị lỗi cho người dùng.
        _showSnackBar('Lỗi tải thông tin địa điểm: $e', isError: true);
      }
    } finally {
      // 4. Khối `finally` **luôn luôn** được thực thi, dù `try` thành công hay `catch`
      //    xảy ra lỗi.
      //    Chúng ta cần đảm bảo `_isLoadingPlace` *luôn* được set về `false`
      //    để tắt vòng quay loading.
      if (mounted) setState(() => _isLoadingPlace = false);
    }
  }

  /// Xử lý chọn ảnh (gọi service)
  // `ImageSource` là một `enum` (kiểu liệt kê) từ `image_picker`,
  // cho phép chúng ta chỉ định `ImageSource.camera` hoặc `ImageSource.gallery`.
  Future<void> _handlePickImage(ImageSource source) async {
    // Đóng BottomSheet (dialog chọn camera/gallery) trước khi mở cửa sổ chọn ảnh.
    if (Navigator.canPop(context)) Navigator.pop(context);

    try {
      // **Luồng hoạt động (setState):**
      if (source == ImageSource.gallery) {
        // 1. Gọi service để chọn nhiều ảnh.
        final images = await _service.pickImagesFromGallery(
          _selectedImages.length, // Số ảnh đang có
          _maxImages, // Số ảnh tối đa
        );
        // 2. Nếu người dùng có chọn ảnh (`images.isNotEmpty`)
        if (images.isNotEmpty) {
          // 3. Cập nhật state: Thêm tất cả ảnh mới vào danh sách `_selectedImages`.
          //    Sử dụng `addAll` để thêm một `List` khác vào `List` hiện tại.
          setState(() => _selectedImages.addAll(images));

          // Thông báo nếu đã đạt giới hạn
          if (_selectedImages.length == _maxImages) {
            _showSnackBar('Đã đạt giới hạn $images ảnh.');
          }
        }
      } else {
        // (source == ImageSource.camera)
        // 1. Gọi service để chụp 1 ảnh.
        final image = await _service.pickImageFromCamera(
          _selectedImages.length,
          _maxImages,
        );
        // 2. Nếu người dùng có chụp ảnh (`image != null`)
        if (image != null) {
          // 3. Cập nhật state: Thêm ảnh vừa chụp vào danh sách.
          //    Sử dụng `add` để thêm một phần tử.
          setState(() => _selectedImages.add(image));
        }
      }
    } catch (e) {
      _showSnackBar("Không thể chọn ảnh: $e", isError: true);
    }
  }

  /// Gửi bài review (gọi service)
  Future<void> _handleSubmitReview() async {
    // === BƯỚC 1: VALIDATION (KIỂM TRA TÍNH HỢP LỆ) ===
    // Kiểm tra dữ liệu đầu vào. Nếu không hợp lệ -> hiển thị SnackBar và `return` (dừng hàm).
    // `trim()`: Xóa khoảng trắng ở đầu và cuối chuỗi trước khi kiểm tra.

    if (_titleController.text.trim().isEmpty) {
      _showSnackBar('Vui lòng nhập Tiêu đề.');
      return;
    }
    if (_commentController.text.trim().isEmpty) {
      _showSnackBar('Vui lòng nhập Nội dung.');
      return;
    }
    // Kiểm tra xem `_selectedPlaceDoc` đã được gán (khác null) hay chưa.
    if (_selectedPlaceDoc == null) {
      _showSnackBar('Vui lòng chọn địa điểm.');
      return;
    }
    if (_selectedImages.isEmpty) {
      _showSnackBar('Vui lòng thêm ít nhất một ảnh.');
      return;
    }

    // Ngăn người dùng bấm nút "Đăng bài" nhiều lần trong khi đang xử lý.
    if (_isSaving) return;

    // === BƯỚC 2: BẮT ĐẦU QUÁ TRÌNH LƯU ===

    // 1. Cập nhật state `_isSaving = true`.
    //    -> UI sẽ build lại, hiển thị `CircularProgressIndicator` trên nút.
    setState(() => _isSaving = true);
    _showSnackBar('Đang xử lý...'); // Thông báo cho người dùng biết

    try {
      // === BƯỚC 3: GỌI SERVICE ===
      // `await` cho đến khi service hoàn thành việc:
      // 1. Upload ảnh lên Cloudinary.
      // 2. Ghi dữ liệu review vào Firestore.
      // 3. Cập nhật 'reviewCount' cho 'places'.
      // 4. (Chạy ngầm) Cập nhật 'visitedProverbs' cho 'users'.
      await _service.submitReview(
        // Lấy ID người dùng từ `widget`.
        userId: widget.currentUserId,
        // Dùng `!` vì đã kiểm tra `!= null` ở BƯỚC 1.
        selectedPlaceDoc: _selectedPlaceDoc!,
        // Lấy text đã trim (làm sạch) từ controller.
        title: _titleController.text.trim(),
        comment: _commentController.text.trim(),
        hashtags: _hashtags, // Truyền danh sách hashtag
        selectedImages: _selectedImages, // Truyền danh sách ảnh (XFile)
      );

      // === BƯỚC 4: XỬ LÝ KHI THÀNH CÔNG ===
      _showSnackBar('Đăng bài check-in thành công!');

      // Kiểm tra `mounted` trước khi điều hướng (rất quan trọng sau `await`).
      if (mounted) {
        // Đóng màn hình CheckinScreen và quay lại màn hình trước đó.
        Navigator.pop(context);
      }
    } catch (e) {
      // === BƯỚC 5: XỬ LÝ KHI THẤT BẠI ===
      _showSnackBar('Lỗi khi đăng bài: $e', isError: true);
    } finally {
      // === BƯỚC 6: DỌN DẸP (LUÔN CHẠY) ===
      // Dù thành công hay thất bại, cũng phải set `_isSaving = false`
      // để người dùng có thể thử lại (nếu lỗi) hoặc nút trở về bình thường.
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // === HÀM XỬ LÝ UI (SHOW DIALOG, SETSTATE...) ===

  /// Hiển thị dialog chọn Nguồn ảnh
  void _showImageSourceDialog() {
    // `showModalBottomSheet` là một hàm của Flutter để hiển thị một
    // cửa sổ (sheet) trượt lên từ dưới đáy màn hình.
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        // `SafeArea` để tránh các vùng "tai thỏ", "nốt ruồi"
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min, // Cột chỉ cao vừa đủ nội dung
            crossAxisAlignment: CrossAxisAlignment
                .stretch, // Các nút bấm kéo dài hết chiều ngang
            children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.photo_library_outlined),
                // Khi bấm, gọi `_handlePickImage` với nguồn là `gallery`.
                onPressed: () => _handlePickImage(ImageSource.gallery),
                label: const Text('Chọn từ thư viện'),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                icon: const Icon(Icons.camera_alt_outlined),
                // Khi bấm, gọi `_handlePickImage` với nguồn là `camera`.
                onPressed: () => _handlePickImage(ImageSource.camera),
                label: const Text('Chụp ảnh mới'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () =>
                    Navigator.pop(context), // Nút này chỉ để đóng dialog
                child: const Text('Hủy'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Hiển thị Mini Map Picker
  void _showMiniMapPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Cho phép sheet chiếm > 50% chiều cao màn hình
      backgroundColor: Colors
          .transparent, // Nền trong suốt để `DraggableScrollableSheet` tự bo góc
      builder: (context) => DraggableScrollableSheet(
        // `DraggableScrollableSheet` là widget phức tạp, cho phép người dùng
        // kéo (drag) để thay đổi kích thước của sheet.
        initialChildSize: 0.7, // Kích thước ban đầu (70% màn hình)
        minChildSize: 0.3, // Kích thước nhỏ nhất (30%)
        maxChildSize: 0.9, // Kích thước lớn nhất (90%)
        expand: false,
        builder: (_, controller) => MiniMapPicker(
          // <-- GỌI WIDGET MỚI
          scrollController:
              controller, // Truyền `controller` của DraggableSheet cho ListView bên trong MiniMapPicker
          // **Luồng hoạt động (Callback):**
          // Đây là cách `MiniMapPicker` (widget con) trả dữ liệu về
          // cho `CheckinScreen` (widget cha).
          // 1. `MiniMapPicker` nhận vào một hàm `onPlaceSelected`.
          // 2. Khi người dùng chọn 1 địa điểm (trong `MiniMapPicker`), nó sẽ
          //    gọi hàm này và truyền `placeDoc` (địa điểm đã chọn) vào.
          onPlaceSelected: (placeDoc) {
            // 3. Hàm này (được định nghĩa ở phía cha) được thực thi.
            if (mounted) {
              // 4. Cập nhật state `_selectedPlaceDoc` của `CheckinScreen`.
              setState(() => _selectedPlaceDoc = placeDoc);
            }
            // 5. Đóng MiniMapPicker.
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  // --- Logic Hashtag (Giữ lại vì setState trực tiếp) ---
  // Các hàm này được giữ lại trực tiếp trong `_CheckinScreenState` (thay vì
  // đưa vào service) vì chúng thao tác trực tiếp với các biến
  // trạng thái (như `_hashtags`, `_hashtagController`) và gọi `setState`
  // ngay lập tức để cập nhật UI.

  void _addHashtag() {
    final tag = _hashtagController.text
        .trim()
        .toLowerCase(); // Lấy, làm sạch, đổi về chữ thường

    // Kiểm tra: tag không rỗng, tag chưa có trong list, và list chưa đầy (5)
    if (tag.isNotEmpty && !_hashtags.contains(tag) && _hashtags.length < 5) {
      // Gọi `setState` để cập nhật cả `_hashtags` và `_hashtagController`.
      setState(() {
        // Tự động thêm dấu '#' nếu người dùng quên
        _hashtags.add(tag.startsWith('#') ? tag : '#$tag');
        _hashtagController.clear(); // Xóa text trong ô nhập
      });
    } else if (_hashtags.length >= 5) {
      _showSnackBar('Đã đạt tối đa 5 Hashtag.');
    }
  }

  void _removeHashtag(String tag) {
    // Gọi `setState` để xóa tag khỏi list.
    setState(() => _hashtags.remove(tag));
  }

  void _addSuggestedTag(String tag) {
    // Tương tự `_addHashtag` nhưng không cần lấy từ controller.
    if (!_hashtags.contains(tag) && _hashtags.length < 5) {
      setState(() => _hashtags.add(tag));
    } else if (_hashtags.length >= 5) {
      _showSnackBar('Đã đạt tối đa 5 Hashtag.');
    }
  }

  @override
  // `build` là hàm quan trọng nhất, nó mô tả UI của widget.
  // Hàm này được gọi lại **mỗi khi `setState` được gọi**.
  Widget build(BuildContext context) {
    // `Scaffold` là cấu trúc cơ bản cho một màn hình (thường có AppBar, Body).
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Checkin',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: kAppbarColor, // Sử dụng hằng số màu đã định nghĩa
        elevation: 0, // Bỏ bóng mờ dưới AppBar
        centerTitle: true,
        leading: IconButton(
          // Nút back bên trái
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        // Đảm bảo nội dung không bị che bởi các thành phần hệ thống
        child: SingleChildScrollView(
          // **Rất quan trọng:** Dùng `SingleChildScrollView` bọc `Column`
          // để khi bàn phím ảo hiện lên (lúc nhập tiêu đề, comment),
          // nội dung có thể cuộn lên, tránh lỗi "Bottom overflowed".
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, // Căn lề trái
            children: [
              // === SỬ DỤNG CÁC WIDGET ĐÃ TÁCH ===
              // Đây là một cấu trúc rất tốt: file `build` chính rất gọn gàng.
              // Chúng ta truyền các *biến trạng thái* (như `_selectedImages`) và
              // các *hàm xử lý* (như `_showImageSourceDialog`) vào các widget con.

              // 1. Image Section
              ImageSection(
                selectedImages: _selectedImages, // Truyền (pass) state
                maxImages: _maxImages, // Truyền (pass) config
                onAddImage:
                    _showImageSourceDialog, // Truyền (pass) một hàm (function pointer)
                // Định nghĩa logic xóa trực tiếp ở đây.
                // Khi `ImageSection` (hoặc `ImageItem` bên trong nó) gọi
                // `onRemoveImage(imageFile)`, hàm ẩn danh (anonymous function) này
                // sẽ được thực thi.
                onRemoveImage: (imageFile) {
                  // Gọi `setState` để xóa ảnh khỏi `_selectedImages`.
                  setState(() {
                    _selectedImages.removeWhere(
                      (f) => f.path == imageFile.path,
                    );
                  });
                },
              ),
              const SizedBox(height: 24), // Khoảng đệm
              // 2. Journey Content
              JourneyContentSection(
                // Truyền các controller để các `TextField` bên trong
                // `JourneyContentSection` có thể kết nối với chúng.
                titleController: _titleController,
                commentController: _commentController,
              ),
              const SizedBox(height: 24),

              // 3. Place Section
              PlaceSection(
                selectedPlaceDoc: _selectedPlaceDoc, // Truyền địa điểm đã chọn
                isLoadingPlace: _isLoadingPlace, // Truyền trạng thái loading
                onShowMiniMap: _showMiniMapPicker, // Truyền hàm mở map
                onClearPlace: () {
                  // Định nghĩa logic xóa địa điểm
                  // Đơn giản là set state về `null`.
                  setState(() => _selectedPlaceDoc = null);
                },
              ),
              const SizedBox(height: 24),

              // 4. Hashtag Section
              HashtagSection(
                hashtags: _hashtags,
                suggestedTags: _suggestedTags,
                hashtagController: _hashtagController,
                onAddHashtag: _addHashtag, // Truyền hàm thêm
                onRemoveHashtag: _removeHashtag, // Truyền hàm xóa
                onAddSuggestedTag: _addSuggestedTag, // Truyền hàm thêm (gợi ý)
              ),
              const SizedBox(height: 24),

              // 5. Privacy Section
              PrivacySection(
                onTap: () {
                  // Chức năng này chưa làm, chỉ hiện SnackBar.
                  _showSnackBar(
                    'Chức năng chọn quyền riêng tư chưa được cài đặt.',
                  );
                },
              ),
              const SizedBox(height: 32),

              // 6. Nút Đăng bài
              SizedBox(
                width: double.infinity, // Nút rộng hết cỡ
                child: ElevatedButton(
                  // **Logic hiển thị loading:**
                  // `onPressed` được set là `null` nếu `_isSaving` là `true`.
                  // Điều này sẽ tự động vô hiệu hóa (disable) nút.
                  onPressed: _isSaving ? null : _handleSubmitReview,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kAppbarColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  // **Logic hiển thị loading (phần `child`):**
                  // Sử dụng toán tử 3 ngôi (ternary operator) `condition ? A : B`.
                  child: _isSaving
                      // Nếu đang lưu -> hiển thị vòng quay
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black54,
                          ),
                        )
                      // Nếu không -> hiển thị text
                      : const Text(
                          'Đăng bài',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
