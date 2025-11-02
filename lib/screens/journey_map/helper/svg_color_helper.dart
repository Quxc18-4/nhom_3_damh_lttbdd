// File: screens/journey_map/helper/svg_color_helper.dart

/// Tô màu các đường path SVG dựa trên một Set các ID tỉnh thành.
///
/// [svgContent]: Nội dung chuỗi của file SVG gốc.
/// [provinceIdsToColor]: Một Set các chuỗi ID (ví dụ: "ha_noi")
///     cần được tô màu.
/// Trả về một chuỗi SVG mới đã được tô màu.
String colorSvgPaths(String svgContent, Set<String> provinceIdsToColor) {
  String coloredSvg = svgContent;
  const String fillColor = "#ede31c"; // Giữ nguyên màu vàng của bạn
  const double fillOpacity = 0.8;

  for (String provinceId in provinceIdsToColor) {
    // Biểu thức chính quy tìm thẻ path có id
    final pattern = RegExp('(<path[^>]*id="$provinceId"[^>]*?)(/?>)');
    coloredSvg = coloredSvg.replaceFirstMapped(pattern, (match) {
      String pathTag = match.group(1)!;
      String closing = match.group(2)!;

      // Xóa thuộc tính fill và style cũ để ghi đè
      pathTag = pathTag.replaceAll(RegExp(r'\sfill="[^"]*"'), '');
      pathTag = pathTag.replaceAll(RegExp(r'\sstyle="[^"]*"'), '');

      // Thêm thuộc tính fill mới
      return '$pathTag fill="$fillColor" fill-opacity="$fillOpacity" $closing';
    });
  }
  return coloredSvg;
}
