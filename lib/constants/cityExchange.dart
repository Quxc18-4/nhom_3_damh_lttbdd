// File: journey_map_constants.dart

// === DI CHUYỂN TỪ journeyMapScreen.dart (lines 31-64) ===
// Đây là 34 ID ĐƠN VỊ HÀNH CHÍNH MỚI (theo ảnh)
final List<String> kAllProvinceIds = [
  "tuyen_quang",
  "yen_bai", // ID này đại diện cho 'Lào Cai' mới (gộp Lào Cai + Yên Bái)
  "thai_nguyen",
  "phu_tho",
  "bac_ninh",
  "hung_yen",
  "hai_phong",
  "ninh_binh",
  "quang_tri",
  "da_nang",
  "quang_ngai",
  "gia_lai",
  "khanh_hoa",
  "lam_dong",
  "dak_lak",
  "ho_chi_minh",
  "dong_nai",
  "tay_ninh",
  "vinh_long",
  "dong_thap",
  "ca_mau",
  "an_giang",
  "can_tho",
  "cao_bang",
  "ha_noi",
  "quang_ninh",
  "lai_chau",
  "dien_bien",
  "son_la",
  "lang_son",
  "thanh_hoa",
  "nghe_an",
  "ha_tinh",
  "hue",
];

// === DI CHUYỂN TỪ journeyMapScreen.dart (lines 68-103) ===
// Tên hiển thị cho 34 ĐƠN VỊ HÀNH CHÍNH MỚI
final Map<String, String> kProvinceDisplayNames = {
  // --- Nhóm gộp (tên chính) ---
  "tuyen_quang": "Tuyên Quang",
  "yen_bai": "Lào Cai", // Tên hiển thị là 'Lào Cai' (gộp Lào Cai + Yên Bái)
  "thai_nguyen": "Thái Nguyên",
  "phu_tho": "Phú Thọ",
  "bac_ninh": "Bắc Ninh",
  "hung_yen": "Hưng Yên",
  "hai_phong": "TP. Hải Phòng",
  "ninh_binh": "Ninh Bình",
  "quang_tri": "Quảng Trị",
  "da_nang": "TP. Đà Nẵng",
  "quang_ngai": "Quảng Ngãi",
  "gia_lai": "Gia Lai",
  "khanh_hoa": "Khánh Hòa",
  "lam_dong": "Lâm Đồng",
  "dak_lak": "Đắk Lắk",
  "ho_chi_minh": "TP. Hồ Chí Minh",
  "dong_nai": "Đồng Nai",
  "tay_ninh": "Tây Ninh",
  "vinh_long": "Vĩnh Long",
  "dong_thap": "Đồng Tháp",
  "ca_mau": "Cà Mau",
  "an_giang": "An Giang",
  "can_tho": "TP. Cần Thơ",
  // --- Các tỉnh/vùng riêng (11 đơn vị không gộp) ---
  "cao_bang": "Cao Bằng",
  "ha_noi": "TĐ. Hà Nội",
  "quang_ninh": "Quảng Ninh",
  "lai_chau": "Lai Châu",
  "dien_bien": "Điện Biên",
  "son_la": "Sơn La",
  "lang_son": "Lạng Sơn",
  "thanh_hoa": "Thanh Hóa",
  "nghe_an": "Nghệ An",
  "ha_tinh": "Hà Tĩnh",
  "hue": "TP. Huế",
};

// === DI CHUYỂN TỪ journeyMapScreen.dart (lines 505-511) ===
String formatProvinceIdToName(String id) {
  return kProvinceDisplayNames[id] ?? id.toUpperCase();
}

// =================================================================
// === BỔ SUNG MỚI: CHUẨN HÓA DỮ LIỆU TỪ GEOLOCATOR ===
// =================================================================

///
/// Bản đồ này ánh xạ các tên tỉnh/thành phố CŨ (có thể
/// lấy từ geolocator) sang ID của đơn vị hành chính MỚI (đã gộp).
///
/// - `key`: Tên tỉnh/thành phố (đã chuẩn hóa, lowercase, không dấu)
/// - `value`: ID chuẩn của 1 trong 34 đơn vị hành chính mới (từ `kAllProvinceIds`)
///
final Map<String, String> _kOldProvinceNameToNewId = {
  // === 11 ĐƠN VỊ KHÔNG SÁP NHẬP ===
  "ha noi": "ha_noi",
  "thanh pho ha noi": "ha_noi",
  "thu do ha noi": "ha_noi",

  "quang ninh": "quang_ninh",
  "tinh quang ninh": "quang_ninh",

  "lai chau": "lai_chau",
  "tinh lai chau": "lai_chau",

  "son la": "son_la",
  "tinh son la": "son_la",

  "dien bien": "dien_bien",
  "tinh dien bien": "dien_bien",

  "thanh hoa": "thanh_hoa",
  "tinh thanh hoa": "thanh_hoa",

  "nghe an": "nghe_an",
  "tinh nghe an": "nghe_an",

  "thua thien hue": "hue",
  "tinh thua thien hue": "hue",
  "hue": "hue",

  "lang son": "lang_son",
  "tinh lang son": "lang_son",

  "ha tinh": "ha_tinh",
  "tinh ha tinh": "ha_tinh",

  "cao bang": "cao_bang",
  "tinh cao bang": "cao_bang",

  // === 23 ĐƠN VỊ SÁP NHẬP MỚI ===

  // Tuyên Quang (Tuyên Quang+Hà Giang)
  "tuyen quang": "tuyen_quang",
  "tinh tuyen quang": "tuyen_quang",
  "ha giang": "tuyen_quang",
  "tinh ha giang": "tuyen_quang",

  // Lào Cai (Lào Cai+Yên Bái) -> ID: "yen_bai"
  "lao cai": "yen_bai",
  "tinh lao cai": "yen_bai",
  "yen bai": "yen_bai",
  "tinh yen bai": "yen_bai",

  // Thái Nguyên (Thái Nguyên+Bắc Kạn)
  "thai nguyen": "thai_nguyen",
  "tinh thai nguyen": "thai_nguyen",
  "bac kan": "thai_nguyen",
  "tinh bac kan": "thai_nguyen",
  "bac can": "thai_nguyen",
  "tinh bac can": "thai_nguyen",

  // Phú Thọ (Phú Thọ, Vĩnh Phúc, Hòa Bình)
  "phu tho": "phu_tho",
  "tinh phu tho": "phu_tho",
  "vinh phuc": "phu_tho",
  "tinh vinh phuc": "phu_tho",
  "hoa binh": "phu_tho",
  "tinh hoa binh": "phu_tho",

  // Bắc Ninh (Bắc Ninh, Bắc Giang)
  "bac ninh": "bac_ninh",
  "tinh bac ninh": "bac_ninh",
  "bac giang": "bac_ninh",
  "tinh bac giang": "bac_ninh",

  // Hưng Yên (Hưng Yên, Thái Bình)
  "hung yen": "hung_yen",
  "tinh hung yen": "hung_yen",
  "thai binh": "hung_yen",
  "tinh thai binh": "hung_yen",

  // TP. Hải Phòng (TP. Hải Phòng, Hải Dương)
  "hai phong": "hai_phong",
  "thanh pho hai phong": "hai_phong",
  "hai duong": "hai_phong",
  "tinh hai duong": "hai_phong",

  // Ninh Bình (Ninh Bình, Nam Định, Hà Nam)
  "ninh binh": "ninh_binh",
  "tinh ninh binh": "ninh_binh",
  "nam dinh": "ninh_binh",
  "tinh nam dinh": "ninh_binh",
  "ha nam": "ninh_binh",
  "tinh ha nam": "ninh_binh",

  // Quảng Trị (Quảng Trị, Quảng Bình)
  "quang tri": "quang_tri",
  "tinh quang tri": "quang_tri",
  "quang binh": "quang_tri",
  "tinh quang binh": "quang_tri",

  // TP. Đà Nẵng (TP. Đà Nẵng, Quảng Nam)
  "da nang": "da_nang",
  "thanh pho da nang": "da_nang",
  "quang nam": "da_nang",
  "tinh quang nam": "da_nang",

  // Quảng Ngãi (Quảng Ngãi, Kon Tum)
  "quang ngai": "quang_ngai",
  "tinh quang ngai": "quang_ngai",
  "kon tum": "quang_ngai",
  "tinh kon tum": "quang_ngai",

  // Gia Lai (Gia Lai, Bình Định)
  "gia lai": "gia_lai",
  "tinh gia lai": "gia_lai",
  "binh dinh": "gia_lai",
  "tinh binh dinh": "gia_lai",

  // Khánh Hòa (Khánh Hòa, Ninh Thuận)
  "khanh hoa": "khanh_hoa",
  "tinh khanh hoa": "khanh_hoa",
  "ninh thuan": "khanh_hoa",
  "tinh ninh thuan": "khanh_hoa",

  // Lâm Đồng (Lâm Đồng, Bình Thuận, Đắk Nông)
  "lam dong": "lam_dong",
  "tinh lam dong": "lam_dong",
  "binh thuan": "lam_dong",
  "tinh binh thuan": "lam_dong",
  "dak nong": "lam_dong",
  "tinh dak nong": "lam_dong",
  "dac nong": "lam_dong",
  "tinh dac nong": "lam_dong",

  // Đắk Lắk (Đắk Lắk, Phú Yên)
  "dak lak": "dak_lak",
  "tinh dak lak": "dak_lak",
  "dac lak": "dak_lak",
  "tinh dac lak": "dak_lak",
  "phu yen": "dak_lak",
  "tinh phu yen": "dak_lak",

  // TP. Hồ Chí Minh (TP.HCM, Bình Dương, Bà Rịa Vũng Tàu)
  "ho chi minh": "ho_chi_minh",
  "thanh pho ho chi minh": "ho_chi_minh", // <<< ĐÂY LÀ FIX
  "hcm": "ho_chi_minh",
  "sai gon": "ho_chi_minh",
  "binh duong": "ho_chi_minh",
  "tinh binh duong": "ho_chi_minh",
  "ba ria vung tau": "ho_chi_minh",
  "tinh ba ria vung tau": "ho_chi_minh", // <<< ĐÂY LÀ FIX
  "vung tau": "ho_chi_minh",

  // Đồng Nai (Đồng Nai, Bình Phước)
  "dong nai": "dong_nai",
  "tinh dong nai": "dong_nai",
  "binh phuoc": "dong_nai",
  "tinh binh phuoc": "dong_nai",

  // Tây Ninh (Tây Ninh, Long An)
  "tay ninh": "tay_ninh",
  "tinh tay ninh": "tay_ninh",
  "long an": "tay_ninh",
  "tinh long an": "tay_ninh",

  // TP. Cần Thơ (TP. Cần Thơ, Sóc Trăng, Hậu Giang)
  "can tho": "can_tho",
  "thanh pho can tho": "can_tho",
  "soc trang": "can_tho",
  "tinh soc trang": "can_tho",
  "hau giang": "can_tho",
  "tinh hau giang": "can_tho",

  // Vĩnh Long (Vĩnh Long, Bến Tre, Trà Vinh)
  "vinh long": "vinh_long",
  "tinh vinh long": "vinh_long",
  "ben tre": "vinh_long",
  "tinh ben tre": "vinh_long",
  "tra vinh": "vinh_long",
  "tinh tra vinh": "vinh_long",

  // Đồng Tháp (Đồng Tháp, Tiền Giang)
  "dong thap": "dong_thap",
  "tinh dong thap": "dong_thap",
  "tien giang": "dong_thap",
  "tinh tien giang": "dong_thap",

  // Cà Mau (Cà Mau, Bạc Liêu)
  "ca mau": "ca_mau",
  "tinh ca mau": "ca_mau",
  "bac lieu": "ca_mau",
  "tinh bac lieu": "ca_mau",

  // An Giang (An Giang, Kiên Giang)
  "an giang": "an_giang",
  "tinh an giang": "an_giang",
  "kien giang": "an_giang",
  "tinh kien giang": "an_giang",
};

/// Hàm tiện ích để chuẩn hóa tên tỉnh từ Geolocator (hoặc input)
/// sang ID tỉnh đã sáp nhập (chuẩn 34 đơn vị mới).
///
/// Ví dụ:
/// - "Vũng Tàu" -> "ho_chi_minh"
/// - "Tỉnh Bà Rịa - Vũng Tàu" -> "ho_chi_minh"
/// - "Hà Giang" -> "tuyen_quang"
/// - "Hà Nội" -> "ha_noi"
///
/// Trả về `null` nếu không nhận diện được.
String? getMergedProvinceIdFromGeolocator(String? placemarkName) {
  if (placemarkName == null || placemarkName.isEmpty) {
    return null;
  }

  // 1. Chuẩn hóa chuỗi đầu vào (lowercase, trim)
  String normalized = placemarkName.toLowerCase().trim();
  // Ví dụ: "thành phố hồ chí minh"

  // 2. BỎ DẤU TIẾNG VIỆT
  normalized = _removeVietnameseDiacritics(normalized);
  // Ví dụ: "thanh pho ho chi minh"

  // 3. Bỏ dấu câu và chuẩn hóa khoảng trắng
  normalized = normalized
      .replaceAll(RegExp(r'[^\w\s]'), '') // Bỏ dấu câu (như '-')
      .replaceAll(RegExp(r'\s+'), ' ') // Chuẩn hóa nhiều khoảng trắng
      .trim();
  // Ví dụ: "thanh pho ho chi minh"

  // 4. TRỰC TIẾP TRA CỨU (ĐÃ XÓA BƯỚC CẮT TIỀN TỐ)
  //    Sẽ tìm chính xác "thanh pho ho chi minh" trong bản đồ
  return _kOldProvinceNameToNewId[normalized];
}

/// Hàm nội bộ để bỏ dấu tiếng Việt
String _removeVietnameseDiacritics(String str) {
  return str
      .replaceAll(RegExp(r'[àáạảãâầấậẩẫăằắặẳẵ]'), 'a')
      .replaceAll(RegExp(r'[èéẹẻẽêềếệểễ]'), 'e')
      .replaceAll(RegExp(r'[ìíịỉĩ]'), 'i')
      .replaceAll(RegExp(r'[òóọỏõôồốộổỗơờớợởỡ]'), 'o')
      .replaceAll(RegExp(r'[ùúụủũưừứựửữ]'), 'u')
      .replaceAll(RegExp(r'[ỳýỵỷỹ]'), 'y')
      .replaceAll(RegExp(r'[đ]'), 'd');
}
