// File: journey_map_constants.dart

// === DI CHUYỂN TỪ journeyMapScreen.dart (lines 31-64) ===
final List<String> kAllProvinceIds = [
  "tuyen_quang",
  "yen_bai",
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
final Map<String, String> kProvinceDisplayNames = {
  // --- Nhóm gộp (tên chính) ---
  "tuyen_quang": "Tuyên Quang",
  "yen_bai": "Yên Bái",
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
  // --- Các tỉnh/vùng riêng ---
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
// (Đổi tên thành hàm top-level và dùng kProvinceDisplayNames)
String formatProvinceIdToName(String id) {
  return kProvinceDisplayNames[id] ?? id.toUpperCase();
}
