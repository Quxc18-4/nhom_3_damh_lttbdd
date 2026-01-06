import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  group('CheckinScreen - Validation Logic Analysis', () {
    // Hàm bổ trợ để in log so sánh kết quả trực quan
    void verifyResult(
      ValidationResult actual,
      bool expectedValid,
      String? expectedError,
      String tcName,
    ) {
      print('--- Analysis: $tcName ---');
      print('  Expected: [isValid: $expectedValid, Error: "$expectedError"]');
      print(
        '  Actual  : [isValid: ${actual.isValid}, Error: "${actual.errorMessage}"]',
      );

      // Lệnh expect thực hiện so sánh, nếu sai lệch sẽ báo Fail test case
      expect(actual.isValid, expectedValid);
      expect(actual.errorMessage, expectedError);

      print('  => Result: MATCHED (Pass)');
    }

    test('[STT 1] Trống tất cả dữ liệu', () {
      final result = validateCheckinForm(
        selectedImages: [],
        title: "",
        comment: "",
        hasPlace: false,
      );

      verifyResult(
        result,
        false,
        'Vui lòng thêm ít nhất một ảnh.',
        'TC 1: Empty Form',
      );
    });

    test('[STT 2] Vượt quá giới hạn 10 ảnh', () {
      final result = validateCheckinForm(
        selectedImages: List.generate(11, (_) => XFile('img.jpg')),
        title: "Dalat Trip",
        comment: "Enjoying the weather",
        hasPlace: true,
      );

      verifyResult(
        result,
        false,
        'Vui lòng thêm tối đa 10 ảnh.',
        'TC 2: Max Images Exceeded',
      );
    });

    test('[STT 3] Tiêu đề rỗng hoặc chỉ có khoảng trắng', () {
      final result = validateCheckinForm(
        selectedImages: [XFile('img.jpg')],
        title: "   ",
        comment: "Good vibe",
        hasPlace: true,
      );

      verifyResult(
        result,
        false,
        'Vui lòng nhập Tiêu đề.',
        'TC 3: Empty Title (Trim)',
      );
    });

    test('[STT 4] Nội dung chia sẻ rỗng', () {
      final result = validateCheckinForm(
        selectedImages: [XFile('img.jpg')],
        title: "Chào đón năm 2026",
        comment: "",
        hasPlace: true,
      );

      verifyResult(
        result,
        false,
        'Vui lòng nhập Nội dung.',
        'TC 4: Empty Comment',
      );
    });

    test('[STT 5] Chưa chọn địa điểm', () {
      final result = validateCheckinForm(
        selectedImages: [XFile('img.jpg')],
        title: "Chào đón năm 2026",
        comment: "Bỏ lại mọi sự buồn bã...",
        hasPlace: false,
      );

      verifyResult(
        result,
        false,
        'Vui lòng chọn địa điểm.',
        'TC 5: Missing Place',
      );
    });

    test('[STT 6] Đầy đủ thông tin hợp lệ', () {
      final result = validateCheckinForm(
        selectedImages: [XFile('img.jpg')],
        title: "Chào đón năm 2026",
        comment: "Mọi sự tốt đẹp",
        hasPlace: true,
      );

      verifyResult(result, true, null, 'TC 6: Valid Form');
    });

    test('[STT 7] Thứ tự ưu tiên (Thiếu ảnh và Tiêu đề)', () {
      // Theo logic _handleSubmitReview, kiểm tra ảnh rỗng sẽ return trước
      final result = validateCheckinForm(
        selectedImages: [],
        title: "",
        comment: "Valid",
        hasPlace: true,
      );

      verifyResult(
        result,
        false,
        'Vui lòng thêm ít nhất một ảnh.',
        'TC 7: Priority Check',
      );
    });

    test('[STT 8] Kiểm tra biên (Đúng 10 ảnh)', () {
      final result = validateCheckinForm(
        selectedImages: List.generate(10, (_) => XFile('img.jpg')),
        title: "Perfect",
        comment: "Limit test",
        hasPlace: true,
      );

      verifyResult(result, true, null, 'TC 8: Boundary 10 Images');
    });
  });
}

// === LOGIC CỦA _handleSubmitReview ĐƯỢC TRÍCH XUẤT ĐỂ KIỂM THỬ ===

class ValidationResult {
  final bool isValid;
  final String? errorMessage;
  ValidationResult({required this.isValid, this.errorMessage});
}

ValidationResult validateCheckinForm({
  required List<XFile> selectedImages,
  required String title,
  required String comment,
  required bool hasPlace,
}) {
  // Logic kiểm soát theo đúng trình tự if-else trong _handleSubmitReview của bạn
  if (selectedImages.isEmpty) {
    return ValidationResult(
      isValid: false,
      errorMessage: 'Vui lòng thêm ít nhất một ảnh.',
    );
  }
  if (selectedImages.length > 10) {
    return ValidationResult(
      isValid: false,
      errorMessage: 'Vui lòng thêm tối đa 10 ảnh.',
    );
  }
  if (title.trim().isEmpty) {
    return ValidationResult(
      isValid: false,
      errorMessage: 'Vui lòng nhập Tiêu đề.',
    );
  }
  if (comment.trim().isEmpty) {
    return ValidationResult(
      isValid: false,
      errorMessage: 'Vui lòng nhập Nội dung.',
    );
  }
  if (!hasPlace) {
    return ValidationResult(
      isValid: false,
      errorMessage: 'Vui lòng chọn địa điểm.',
    );
  }
  return ValidationResult(isValid: true);
}
