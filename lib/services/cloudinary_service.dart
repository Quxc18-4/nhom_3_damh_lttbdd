import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';

// ⚠️ THAY THẾ CÁC GIÁ TRỊ NÀY BẰNG THÔNG TIN CỦA DỰ ÁN CỦA BẠN ⚠️
const String CLOUDINARY_CLOUD_NAME = 'dkzmro70z';
const String CLOUDINARY_UPLOAD_PRESET = 'triply';
// Không cần API Key và Secret nếu dùng Upload Preset (phương pháp an toàn nhất từ client)

class CloudinaryService {
  final ImagePicker _picker = ImagePicker();

  // 1. CHỌN ẢNH TỪ THƯ VIỆN
  /// Mở thư viện ảnh của thiết bị và trả về File ảnh đã chọn.
  Future<File?> pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      return File(pickedFile.path);
    }
    return null;
  }

  // 2. TẢI ẢNH LÊN CLOUDINARY
  /// Thực hiện tải ảnh lên Cloudinary sử dụng unsigned upload preset.
  /// Trả về URL của ảnh đã được tải lên, hoặc null nếu lỗi.
  Future<String?> uploadImageToCloudinary(File imageFile) async {
    // 1. Xây dựng URL API
    final String uploadUrl = 'https://api.cloudinary.com/v1_1/$CLOUDINARY_CLOUD_NAME/image/upload';

    // 2. Tạo MultiPart Request
    var request = http.MultipartRequest('POST', Uri.parse(uploadUrl));

    // 3. Thêm các trường dữ liệu (Form fields)
    // upload_preset là bắt buộc cho unsigned upload
    request.fields['upload_preset'] = CLOUDINARY_UPLOAD_PRESET;
    // request.fields['folder'] = 'Triply_App_Images'; // Tùy chọn: Thư mục lưu trữ

    // 4. Thêm file ảnh vào request
    var filePart = await http.MultipartFile.fromPath(
      'file', // Tên trường file trong Cloudinary API là 'file'
      imageFile.path,
    );
    request.files.add(filePart);

    try {
      // 5. Gửi request
      var response = await request.send();

      if (response.statusCode == 200) {
        // 6. Xử lý phản hồi thành công
        var responseBody = await response.stream.bytesToString();
        var data = jsonDecode(responseBody);

        // Trả về URL an toàn (secure_url)
        String imageUrl = data['secure_url'];
        print('Cloudinary upload successful: $imageUrl');
        return imageUrl;
      } else {
        // Xử lý lỗi
        var responseBody = await response.stream.bytesToString();
        print('Cloudinary upload failed with status ${response.statusCode}: $responseBody');
        return null;
      }
    } catch (e) {
      print('Exception during upload: $e');
      return null;
    }
  }
}
