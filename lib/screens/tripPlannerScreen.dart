import 'package:flutter/material.dart';
import 'dart:convert';
// Cần cập nhật đường dẫn import cho phù hợp với cấu trúc project của bạn
import '../model/travel_day.dart'; 
import '../services/local_plan_service.dart';
import 'package:nhom_3_damh_lttbdd/model/activity.dart'; 

class TravelPlanPage extends StatefulWidget {
  const TravelPlanPage({super.key});

  @override
  State<TravelPlanPage> createState() => _TravelPlanPageState();
}

class _TravelPlanPageState extends State<TravelPlanPage>
    with SingleTickerProviderStateMixin {
  // Service để lưu/tải dữ liệu
  final LocalPlanService _localPlanService = LocalPlanService();

  late TabController _tabController;

  bool _isDeleteMode = false;
  bool _isAddingActivity = false;

  // Dữ liệu chính: List<TravelDay> được tải từ local
  List<TravelDay> _travelPlan = []; 

  // Ngày bắt đầu (mặc định là hôm nay)
  DateTime _startDate = DateTime.now();

  // Tạo thông tin ngày động dựa trên _startDate
  List<Map<String, dynamic>> _generateDayInfo() {
    List<Map<String, dynamic>> dayInfo = [];
    for (int i = 0; i < 7; i++) {
      DateTime date = _startDate.add(Duration(days: i));
      dayInfo.add({
        'day': i + 1,
        'date': '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}',
        'mainColor': _getColorForDay(i).mainColor,
        'accentColor': _getColorForDay(i).accentColor,
      });
    }
    return dayInfo;
  }

  // Ánh xạ màu sắc cho các ngày
  Map<int, ({Color mainColor, Color accentColor})> _dayColors = {
    0: (mainColor: Color(0xFF9933CC), accentColor: Color(0xFFE0B0FF)), // Tím
    1: (mainColor: Color(0xFFFF6699), accentColor: Color(0xFFFFCCF5)), // Hồng
    2: (mainColor: Color(0xFF3399FF), accentColor: Color(0xFFB0D5FF)), // Xanh dương
    3: (mainColor: Color(0xFF4CAF50), accentColor: Color(0xFFC8E6C9)), // Xanh lá
    4: (mainColor: Color(0xFFFFC107), accentColor: Color(0xFFFFECB3)), // Vàng
    5: (mainColor: Color(0xFFE53935), accentColor: Color(0xFFFFCDD2)), // Đỏ
    6: (mainColor: Color(0xFF00BCD4), accentColor: Color(0xFFB2EBF2)), // Xanh ngọc
  };

  ({Color mainColor, Color accentColor}) _getColorForDay(int index) {
    return _dayColors[index % _dayColors.length]!;
  }

  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _detailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadStartDate(); // Tải ngày bắt đầu trước
    _tabController = TabController(length: 7, vsync: this);
    _tabController.addListener(_handleTabChange);
    _loadTravelPlan(); // Tải dữ liệu từ local
  }

  // Tải ngày bắt đầu từ Local Storage
  Future<void> _loadStartDate() async {
    final savedDate = await _localPlanService.loadStartDate();
    if (savedDate != null) {
      setState(() {
        _startDate = savedDate;
      });
    }
  }

  // Lưu ngày bắt đầu vào Local Storage
  Future<void> _saveStartDate() async {
    await _localPlanService.saveStartDate(_startDate);
  }

  // --- LOGIC VỀ DỮ LIỆU VÀ LOCAL STORAGE ---

  // Khởi tạo mẫu hoạt động đơn giản cho Ngày 1 nếu chưa có dữ liệu
  List<Activity> _createSampleActivities(Map<String, dynamic> dayInfo) {
    final Color accentColor = dayInfo['accentColor'] as Color;
    return [
      Activity(time: "4:30", title: "Thức dậy", icon: Icons.wb_sunny_outlined, color: accentColor),
      Activity(time: "5:30", title: "Săn bình minh", icon: Icons.cloud_queue_rounded, color: accentColor),
      Activity(time: "7:30", title: "Ăn sáng", icon: Icons.restaurant, color: accentColor),
    ];
  }

  // Tải dữ liệu từ Local Storage
  Future<void> _loadTravelPlan() async {
    final loadedPlan = await _localPlanService.loadAllDays();
    final dayInfo = _generateDayInfo();

    if (loadedPlan.isEmpty) {
      // Nếu không có dữ liệu, tạo cấu trúc 7 ngày rỗng/mẫu ban đầu
      final initialPlan = List<TravelDay>.generate(dayInfo.length, (index) {
        final info = dayInfo[index];
        return TravelDay(
          day: info['day'] as int,
          date: info['date'] as String,
          tabIndex: index,
          activities: index == 0 ? _createSampleActivities(info) : [],
        );
      });
      await _localPlanService.saveAllDays(initialPlan);
      _sortAllActivities(initialPlan);
      setState(() {
        _travelPlan = initialPlan;
      });
    } else {
      // Đã có dữ liệu, tạo lại danh sách với ngày mới dựa trên _startDate
      final updatedPlan = List<TravelDay>.generate(dayInfo.length, (index) {
        final info = dayInfo[index];
        final oldDay = loadedPlan.length > index ? loadedPlan[index] : null;
        return TravelDay(
          day: info['day'] as int,
          date: info['date'] as String,
          tabIndex: index,
          activities: oldDay?.activities ?? [], // Giữ nguyên hoạt động cũ
        );
      });
      _sortAllActivities(updatedPlan);
      setState(() {
        _travelPlan = updatedPlan;
      });
    }
  }

  // Lưu dữ liệu vào Local Storage
  Future<void> _saveTravelPlan() async {
    await _localPlanService.saveAllDays(_travelPlan);
  }

  // Lấy danh sách hoạt động của ngày đang chọn (dùng Model)
  List<Activity> _getCurrentActivities() {
    if (_tabController.index >= 0 && _tabController.index < _travelPlan.length) {
      return _travelPlan[_tabController.index].activities;
    }
    return [];
  }

  // Sắp xếp hoạt động cho tất cả các ngày
  void _sortAllActivities([List<TravelDay>? plan]) {
    final listToSort = plan ?? _travelPlan;
    for (var day in listToSort) {
      day.activities.sort((a, b) {
        final timeA = _convertTime(a.time);
        final timeB = _convertTime(b.time);
        return timeA.compareTo(timeB);
      });
    }
  }

  // Chuyển đổi thời gian "hh:mm" sang phút để sắp xếp
  int _convertTime(String time) {
    final parts = time.split(":");
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;
    return hour * 60 + minute;
  }

  // Thêm hoạt động vào ngày đang chọn
  void _addActivity() async {
    final time = _timeController.text.trim();
    final title = _titleController.text.trim();
    final detail = _detailController.text.trim(); 
    
    if (time.isNotEmpty && title.isNotEmpty) {
      setState(() {
        final currentDayIndex = _tabController.index;
        final selectedDayInfo = _generateDayInfo()[currentDayIndex];
        
        final newActivity = Activity(
          time: time,
          title: title,
          icon: Icons.place, 
          color: selectedDayInfo['accentColor'] as Color, 
          detail: detail.isEmpty ? null : detail 
        );
        
        _travelPlan[currentDayIndex].activities.add(newActivity);
        
        _travelPlan[currentDayIndex].activities.sort((a, b) => _convertTime(a.time).compareTo(_convertTime(b.time)));
        
        _isAddingActivity = false;
        _timeController.clear();
        _titleController.clear();
        _detailController.clear();
      });
      await _saveTravelPlan(); // LƯU VÀO LOCAL
    }
  }

  // Xóa hoạt động khỏi ngày đang chọn
  void _removeActivity(int index) async {
    setState(() {
      _getCurrentActivities().removeAt(index);
    });
    await _saveTravelPlan(); // LƯU VÀO LOCAL
  }
  
  // --- POPUP & HIỂN THỊ CHI TIẾT ---

  // Hiển thị Popup chi tiết cho MỘT hoạt động (dùng Model)
  void _showDetailPopupFromModel(Activity activity) {
    showDialog(
      context: context,
      builder: (context) {
        final detail = activity.detail ?? ''; 
        
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Text('${activity.time} - ${activity.title}', style: const TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Row(
                  children: [
                    Icon(activity.icon, color: activity.color),
                    const SizedBox(width: 8),
                    const Text('Thời gian: ', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(activity.time),
                  ],
                ),
                const SizedBox(height: 10),
                
                if (detail.isNotEmpty) ...[
                  const Text('Chi tiết:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(detail),
                ],
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Đóng'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // Hiển thị Popup chi tiết cho MỘT ngày (khi nhấn 'Xem tất cả')
  void _showAllActivitiesForDay(int dayIndex) {
    final info = _generateDayInfo()[dayIndex];
    final activities = _travelPlan[dayIndex].activities; 
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, 
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Container(
                width: 40, height: 4, margin: const EdgeInsets.only(bottom: 15),
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
              ),
              Text(
                'Chi tiết Lịch trình Ngày ${info['day']} (${info['date']})',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Divider(),
              // Danh sách hoạt động chi tiết
              Expanded(
                child: ListView(
                  children: activities.map((activity) => _buildActivityItemFromModel(activity, activities.indexOf(activity))).toList(),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  backgroundColor: info['mainColor'] as Color,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Đóng', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        );
      },
    );
  }

  // WIDGET: Thiết kế dạng Capsule (Nhận vào Activity Model)
  Widget _buildActivityCapsuleFromModel(Activity activity, {required Color accentColor}) {
    if (activity.time.isEmpty) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () => _showDetailPopupFromModel(activity),
      child: Container(
        width: double.infinity,
        height: 60, 
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: accentColor.withOpacity(0.3), width: 1),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center, 
          children: [
            // ICON vòng tròn
            Container(
              width: 44, 
              height: 44,
              margin: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: activity.color.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: Center( 
                child: Icon(
                  activity.icon,
                  size: 22, 
                  color: Colors.white,
                ),
              ),
            ),

            // TEXT: giờ + tên
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '${activity.time} ',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      TextSpan(
                        text: activity.title,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // WIDGET: Cột Ngày - Giữ nguyên
  Widget _buildDayColumn(int day, String date, Color color) {
    return Container(
      width: 90,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [color.withOpacity(0.8), color.withOpacity(1)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(right: 8),
      child: Center( 
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center, 
          children: [
            Text(
              'Ngày $day',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              date,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 12,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // WIDGET: Kế hoạch ngày trong Popup Tổng quan (dùng Model)
  Widget _buildDayPlanInPopup(int dayIndex, String date, Color mainColor) {
    final info = _generateDayInfo()[dayIndex];
    final activities = _travelPlan[dayIndex].activities; 
    final accentColor = info['accentColor'] as Color;
    
    const int limit = 5;
    final isOverLimit = activities.length > limit;
    final limitedActivities = isOverLimit ? activities.sublist(0, limit) : activities;

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cột Ngày
            _buildDayColumn(dayIndex + 1, date, mainColor),

            // Phần Hoạt động (1 Cột)
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: mainColor.withOpacity(0.2))
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Hiển thị các hoạt động giới hạn
                    ...limitedActivities.map((activity) => _buildActivityCapsuleFromModel(activity, accentColor: accentColor)).toList(),
                    
                    // Nút "Xem tất cả" nếu vượt quá giới hạn
                    if (isOverLimit)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0, bottom: 4.0, left: 10),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.pop(context); // Đóng popup tổng quan
                            _showAllActivitiesForDay(dayIndex); // Mở popup chi tiết ngày
                          },
                          child: Text.rich(
                            TextSpan( 
                              children: [
                                TextSpan( 
                                  text: 'Xem tất cả ${activities.length} hoạt động ',
                                  style: const TextStyle( 
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                                const WidgetSpan(child: Icon(Icons.arrow_forward_ios, size: 14, color: Colors.blue)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    
                    if (activities.isEmpty)
                      const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text("Chưa có hoạt động nào.", style: TextStyle(color: Colors.grey)),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // HÀM HIỂN THỊ POPUP TỔNG QUAN (Đã cập nhật để dùng dữ liệu 7 ngày từ _travelPlan)
  void _showSharePopup() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, 
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.95,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Thanh kéo ở trên cùng
                Padding(
                  padding: const EdgeInsets.only(top: 10.0),
                  child: Container(
                    width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 12),
                
                // Tiêu đề Popup
                const Text.rich(
                  TextSpan(
                    children: [
                      WidgetSpan(child: Icon(Icons.wb_sunny_outlined, color: Color(0xFF4CAF50), size: 24)),
                      TextSpan(
                        text: ' Travel Plan - 7 Ngày tại Đà Lạt ', 
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
                      ),
                      WidgetSpan(child: Icon(Icons.cloud_outlined, color: Color(0xFF2196F3), size: 24)),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),

                // Danh sách các Ngày (7 ngày)
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        ...List.generate(_travelPlan.length, (index) {
                          final info = _generateDayInfo()[index];
                          return _buildDayPlanInPopup(
                            index, 
                            info['date'] as String, 
                            info['mainColor'] as Color, 
                          );
                        }),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),

                // Thanh điều khiển (Đóng/Tải xuống)
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), spreadRadius: 2, blurRadius: 5, offset: const Offset(0, -3))],
                  ),
                  child: Row(
                    children: [
                      Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context), style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48), side: BorderSide(color: Colors.grey.shade400), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text('Đóng', style: TextStyle(color: Colors.black)))),
                      const SizedBox(width: 10),
                      Expanded(child: ElevatedButton.icon(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.download_outlined, size: 24), label: const Text('Tải xuống', style: TextStyle(fontSize: 16)), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF9800), foregroundColor: Colors.white, minimumSize: const Size.fromHeight(48), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))))),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // WIDGET HOẠT ĐỘNG DẠNG LIST TILE (Nhận vào Activity Model)
  Widget _buildActivityItemFromModel(Activity activity, int index) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        onTap: () => _showDetailPopupFromModel(activity), // Dùng hàm nhận Model
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4), 
        leading: Container(
          width: 42, 
          height: 42,
          decoration: BoxDecoration(
            color: activity.color.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Center( 
            child: Icon(
              activity.icon,
              size: 22, 
              color: activity.color,
            ),
          ),
        ),
        title: Row(
          children: [
            Text(
              activity.time,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                activity.title,
                style: const TextStyle(fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        trailing: _isDeleteMode
            ? GestureDetector(
                onTap: () => _removeActivity(index), 
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.remove, size: 18, color: Colors.white),
                ),
              )
            : null,
      ),
    );
  }

  // WIDGET KẾ HOẠCH NGÀY (Sử dụng _getCurrentActivities() và _buildActivityItemFromModel)
  Widget _buildDayPlan() {
    final activities = _getCurrentActivities();
    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 12, bottom: 200),
      child: Column(
        children: [
          if (_isAddingActivity) _buildAddActivityForm(),
          if (activities.isEmpty && !_isAddingActivity)
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text(
                'Ngày ${_tabController.index + 1} chưa có hoạt động. Thêm hoạt động ngay!',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ),
          ...List.generate(
            activities.length,
            (index) => _buildActivityItemFromModel(activities[index], index),
          ),
        ],
      ),
    );
  }
  
  // WIDGET FORM THÊM HOẠT ĐỘNG
  Widget _buildAddActivityForm() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade100, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Thêm hoạt động cho Ngày ${_tabController.index + 1}", 
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 10),
          
          // 1. Trường Thời gian
          TextField(
            controller: _timeController,
            decoration: InputDecoration(
              hintText: "Thời gian (hh:mm)",
              filled: true,
              fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            keyboardType: TextInputType.datetime,
          ),
          const SizedBox(height: 10),
          
          // 2. Trường Tên hoạt động
          TextField(
            controller: _titleController,
            decoration: InputDecoration(
              hintText: "Tên hoạt động",
              filled: true,
              fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
          
          const SizedBox(height: 10),
          
          // 3. TRƯỜNG MỚI: Chi tiết hoạt động
          TextField(
            controller: _detailController,
            maxLines: 3,
            minLines: 1,
            decoration: InputDecoration(
              hintText: "Chi tiết (Địa điểm, ghi chú, ...)",
              filled: true,
              fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
          
          const SizedBox(height: 15),
          
          // Nút điều khiển
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  setState(() {
                    _isAddingActivity = false;
                    _timeController.clear();
                    _titleController.clear();
                    _detailController.clear();
                  });
                }, 
                child: const Text("Hủy", style: TextStyle(color: Colors.grey))
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _addActivity, 
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue, 
                  foregroundColor: Colors.white, 
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                ), 
                child: const Text("Thêm")
              ),
            ],
          )
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _timeController.dispose();
    _titleController.dispose();
    _detailController.dispose();
    super.dispose();
  }
  
  // Xử lý khi đổi tab để tự động tắt chế độ thêm/xóa
  void _handleTabChange() {
    setState(() {
      _isAddingActivity = false;
      _isDeleteMode = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Hiển thị loading nếu chưa tải xong dữ liệu
    if (_travelPlan.isEmpty && _generateDayInfo().isNotEmpty) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios), color: Colors.black, onPressed: () => Navigator.pop(context)),
        title: const Text('Travel Plan', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today, color: Colors.black),
            tooltip: 'Chọn ngày bắt đầu',
            onPressed: () => _selectStartDate(context),
          ),
          IconButton(icon: const Icon(Icons.share, color: Colors.black), onPressed: _showSharePopup),
          IconButton(icon: const Icon(Icons.download_outlined, color: Colors.black), onPressed: _showSharePopup)
        ],
        // Hiển thị 7 tab
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true, 
          labelColor: Colors.blue,
          unselectedLabelColor: Colors.black,
          indicatorColor: Colors.blue,
          padding: EdgeInsets.zero,
          tabAlignment: TabAlignment.start,
          tabs: _generateDayInfo().map((info) => Tab(
            child: Column(
              children: [
                Text('Day ${info['day']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(info['date'] as String, style: const TextStyle(fontSize: 12)),
              ],
            ),
          )).toList(),
        ),
      ),
      // TabBarView chứa 7 widget _buildDayPlan
      body: Stack(
        children: [
          TabBarView(
            controller: _tabController,
            children: List.generate(_travelPlan.length, (index) => _buildDayPlan()),
          ),
          
          // Footer
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Material(
              elevation: 4,
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ElevatedButton(
                      onPressed: _isAddingActivity ? _addActivity : () {
                        setState(() {
                          _isAddingActivity = true; 
                          if (_isDeleteMode) _isDeleteMode = false;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isAddingActivity ? Colors.blue : const Color(0xFFFFD9B3),
                        foregroundColor: _isAddingActivity ? Colors.white : Colors.black,
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        _isAddingActivity ? 'Lưu hoạt động' : '+ Thêm hoạt động cho Day ${_tabController.index + 1}', 
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _isDeleteMode = !_isDeleteMode;
                          if (_isAddingActivity) _isAddingActivity = false;
                        });
                      },
                      child: Text(
                        _isDeleteMode ? '✕ Hủy bỏ chế độ xoá' : '− Loại bỏ hoạt động',
                        style: const TextStyle(color: Colors.deepOrange, fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: 80, height: 4, decoration: BoxDecoration(color: Colors.black.withOpacity(0.25), borderRadius: BorderRadius.circular(2)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Hiển thị DatePicker để chọn ngày bắt đầu
  Future<void> _selectStartDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      helpText: 'Chọn ngày bắt đầu chuyến đi',
      confirmText: 'Xác nhận',
      cancelText: 'Hủy',
    );
    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
        // Cập nhật ngày tháng trong _travelPlan
        final dayInfo = _generateDayInfo();
        for (int i = 0; i < _travelPlan.length; i++) {
          _travelPlan[i].date = dayInfo[i]['date'] as String;
        }
      });
      await _saveTravelPlan(); // Lưu kế hoạch với ngày mới
      await _saveStartDate(); // Lưu ngày bắt đầu mới
    }
  }
}