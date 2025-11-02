// File: screens/trip_planner/trip_planner_screen.dart

import 'package:flutter/material.dart';
import 'dart:convert';
// Cập nhật đường dẫn import
import 'package:nhom_3_damh_lttbdd/model/travel_day.dart';
import 'package:nhom_3_damh_lttbdd/services/local_plan_service.dart';
import 'package:nhom_3_damh_lttbdd/model/activity.dart';
import 'helper/trip_planner_helper.dart'; // <-- IMPORT HELPER
import 'widget/trip_planner_widgets.dart'; // <-- IMPORT WIDGETS

class TripPlannerScreen extends StatefulWidget {
  // Đổi tên class
  const TripPlannerScreen({super.key});

  @override
  State<TripPlannerScreen> createState() => _TripPlannerScreenState();
}

class _TripPlannerScreenState extends State<TripPlannerScreen>
    with SingleTickerProviderStateMixin {
  // Service
  final LocalPlanService _localPlanService = LocalPlanService();

  // State
  late TabController _tabController;
  bool _isDeleteMode = false;
  bool _isAddingActivity = false;
  List<TravelDay> _travelPlan = [];
  DateTime _startDate = DateTime.now();

  // Controllers
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _detailController = TextEditingController();

  // --- INIT & STATE MANAGEMENT ---

  @override
  void initState() {
    super.initState();
    _loadStartDate();
    _tabController = TabController(length: 7, vsync: this);
    _tabController.addListener(_handleTabChange);
    _loadTravelPlan();
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

  void _handleTabChange() {
    setState(() {
      _isAddingActivity = false;
      _isDeleteMode = false;
    });
  }

  // --- HELPERS (Đã chuyển 2 hàm sang helper) ---

  List<Map<String, dynamic>> _generateDayInfo() {
    List<Map<String, dynamic>> dayInfo = [];
    for (int i = 0; i < 7; i++) {
      DateTime date = _startDate.add(Duration(days: i));
      dayInfo.add({
        'day': i + 1,
        'date':
            '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}',
        'mainColor': getColorForDay(i).mainColor, // <-- GỌI HELPER
        'accentColor': getColorForDay(i).accentColor, // <-- GỌI HELPER
      });
    }
    return dayInfo;
  }

  // _getColorForDay (ĐÃ CHUYỂN SANG HELPER)
  // _convertTime (ĐÃ CHUYỂN SANG HELPER)

  // --- LOCAL STORAGE & DATA LOGIC ---

  Future<void> _loadStartDate() async {
    final savedDate = await _localPlanService.loadStartDate();
    if (savedDate != null) {
      setState(() {
        _startDate = savedDate;
      });
    }
  }

  Future<void> _saveStartDate() async {
    await _localPlanService.saveStartDate(_startDate);
  }

  List<Activity> _createSampleActivities(Map<String, dynamic> dayInfo) {
    final Color accentColor = dayInfo['accentColor'] as Color;
    return [
      Activity(
        time: "4:30",
        title: "Thức dậy",
        icon: Icons.wb_sunny_outlined,
        color: accentColor,
      ),
      Activity(
        time: "5:30",
        title: "Săn bình minh",
        icon: Icons.cloud_queue_rounded,
        color: accentColor,
      ),
      Activity(
        time: "7:30",
        title: "Ăn sáng",
        icon: Icons.restaurant,
        color: accentColor,
      ),
    ];
  }

  Future<void> _loadTravelPlan() async {
    final loadedPlan = await _localPlanService.loadAllDays();
    final dayInfo = _generateDayInfo();

    if (loadedPlan.isEmpty) {
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
      final updatedPlan = List<TravelDay>.generate(dayInfo.length, (index) {
        final info = dayInfo[index];
        final oldDay = loadedPlan.length > index ? loadedPlan[index] : null;
        return TravelDay(
          day: info['day'] as int,
          date: info['date'] as String,
          tabIndex: index,
          activities: oldDay?.activities ?? [],
        );
      });
      _sortAllActivities(updatedPlan);
      setState(() {
        _travelPlan = updatedPlan;
      });
    }
  }

  Future<void> _saveTravelPlan() async {
    await _localPlanService.saveAllDays(_travelPlan);
  }

  List<Activity> _getCurrentActivities() {
    if (_tabController.index >= 0 &&
        _tabController.index < _travelPlan.length) {
      return _travelPlan[_tabController.index].activities;
    }
    return [];
  }

  void _sortAllActivities([List<TravelDay>? plan]) {
    final listToSort = plan ?? _travelPlan;
    for (var day in listToSort) {
      day.activities.sort((a, b) {
        final timeA = convertTimeToMinutes(a.time); // <-- GỌI HELPER
        final timeB = convertTimeToMinutes(b.time); // <-- GỌI HELPER
        return timeA.compareTo(timeB);
      });
    }
  }

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
          detail: detail.isEmpty ? null : detail,
        );

        _travelPlan[currentDayIndex].activities.add(newActivity);

        _travelPlan[currentDayIndex].activities.sort(
          (a, b) => convertTimeToMinutes(
            a.time,
          ).compareTo(convertTimeToMinutes(b.time)),
        ); // <-- GỌI HELPER

        _isAddingActivity = false;
        _timeController.clear();
        _titleController.clear();
        _detailController.clear();
      });
      await _saveTravelPlan();
    }
  }

  void _removeActivity(int index) async {
    setState(() {
      _getCurrentActivities().removeAt(index);
    });
    await _saveTravelPlan();
  }

  // --- POPUP & MODAL CONTROLLERS ---

  void _showDetailPopupFromModel(Activity activity) {
    showDialog(
      context: context,
      builder: (context) {
        final detail = activity.detail ?? '';

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Text(
            '${activity.time} - ${activity.title}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Row(
                  children: [
                    Icon(activity.icon, color: activity.color),
                    const SizedBox(width: 8),
                    const Text(
                      'Thời gian: ',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(activity.time),
                  ],
                ),
                const SizedBox(height: 10),

                if (detail.isNotEmpty) ...[
                  const Text(
                    'Chi tiết:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
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
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 15),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                'Chi tiết Lịch trình Ngày ${info['day']} (${info['date']})',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Divider(),
              Expanded(
                child: ListView(
                  children: activities
                      .map(
                        (activity) => ActivityListItem(
                          // <-- SỬ DỤNG WIDGET MỚI
                          activity: activity,
                          isDeleteMode: false, // Không xóa trong modal này
                          onTap: () => _showDetailPopupFromModel(activity),
                          onRemove: () {},
                        ),
                      )
                      .toList(),
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
                // Thanh kéo
                Padding(
                  padding: const EdgeInsets.only(top: 10.0),
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Tiêu đề
                const Text.rich(
                  TextSpan(
                    children: [
                      WidgetSpan(
                        child: Icon(
                          Icons.wb_sunny_outlined,
                          color: Color(0xFF4CAF50),
                          size: 24,
                        ),
                      ),
                      TextSpan(
                        text: ' Travel Plan - 7 Ngày tại Đà Lạt ',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      WidgetSpan(
                        child: Icon(
                          Icons.cloud_outlined,
                          color: Color(0xFF2196F3),
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),

                // Danh sách
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        ...List.generate(_travelPlan.length, (index) {
                          final info = _generateDayInfo()[index];
                          final activities = _travelPlan[index].activities;
                          // <-- SỬ DỤNG WIDGET MỚI
                          return DayPlanSummaryCard(
                            dayIndex: index,
                            date: info['date'] as String,
                            mainColor: info['mainColor'] as Color,
                            accentColor: info['accentColor'] as Color,
                            activities: activities,
                            onViewAll: () {
                              Navigator.pop(context); // Đóng popup tổng quan
                              _showAllActivitiesForDay(
                                index,
                              ); // Mở popup chi tiết
                            },
                          );
                        }),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),

                // Footer
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 2,
                        blurRadius: 5,
                        offset: const Offset(0, -3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                            side: BorderSide(color: Colors.grey.shade400),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Đóng',
                            style: TextStyle(color: Colors.black),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.download_outlined, size: 24),
                          label: const Text(
                            'Tải xuống',
                            style: TextStyle(fontSize: 16),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF9800),
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
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
        final dayInfo = _generateDayInfo();
        for (int i = 0; i < _travelPlan.length; i++) {
          _travelPlan[i].date = dayInfo[i]['date'] as String;
        }
      });
      await _saveTravelPlan();
      await _saveStartDate();
    }
  }

  // --- WIDGETS BUILD (ĐÃ CHUYỂN PHẦN LỚN) ---

  // _buildActivityCapsuleFromModel (ĐÃ CHUYỂN SANG WIDGET)
  // _buildDayColumn (ĐÃ CHUYỂN SANG WIDGET)
  // _buildDayPlanInPopup (ĐÃ CHUYỂN SANG WIDGET)
  // _buildActivityItemFromModel (ĐÃ CHUYỂN SANG WIDGET)
  // _buildAddActivityForm (ĐÃ CHUYỂN SANG WIDGET)

  /// Widget chính cho nội dung của mỗi Tab
  Widget _buildDayPlan() {
    final activities = _getCurrentActivities();
    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 12, bottom: 200),
      child: Column(
        children: [
          if (_isAddingActivity)
            AddActivityForm(
              // <-- SỬ DỤNG WIDGET MỚI
              currentDay: _tabController.index + 1,
              timeController: _timeController,
              titleController: _titleController,
              detailController: _detailController,
              onCancel: () {
                setState(() {
                  _isAddingActivity = false;
                  _timeController.clear();
                  _titleController.clear();
                  _detailController.clear();
                });
              },
              onAdd: _addActivity,
            ),

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
            (index) => ActivityListItem(
              // <-- SỬ DỤNG WIDGET MỚI
              activity: activities[index],
              isDeleteMode: _isDeleteMode,
              onTap: () => _showDetailPopupFromModel(activities[index]),
              onRemove: () => _removeActivity(index),
            ),
          ),
        ],
      ),
    );
  }

  // --- MAIN BUILD ---

  @override
  Widget build(BuildContext context) {
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          color: Colors.black,
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Travel Plan',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today, color: Colors.black),
            tooltip: 'Chọn ngày bắt đầu',
            onPressed: () => _selectStartDate(context),
          ),
          IconButton(
            icon: const Icon(Icons.share, color: Colors.black),
            onPressed: _showSharePopup,
          ),
          IconButton(
            icon: const Icon(Icons.download_outlined, color: Colors.black),
            onPressed: _showSharePopup,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.blue,
          unselectedLabelColor: Colors.black,
          indicatorColor: Colors.blue,
          padding: EdgeInsets.zero,
          tabAlignment: TabAlignment.start,
          tabs: _generateDayInfo()
              .map(
                (info) => Tab(
                  child: Column(
                    children: [
                      Text(
                        'Day ${info['day']}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        info['date'] as String,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
      ),
      body: Stack(
        children: [
          TabBarView(
            controller: _tabController,
            children: List.generate(
              _travelPlan.length,
              (index) => _buildDayPlan(),
            ),
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
                      onPressed: _isAddingActivity
                          ? _addActivity
                          : () {
                              setState(() {
                                _isAddingActivity = true;
                                if (_isDeleteMode) _isDeleteMode = false;
                              });
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isAddingActivity
                            ? Colors.blue
                            : const Color(0xFFFFD9B3),
                        foregroundColor: _isAddingActivity
                            ? Colors.white
                            : Colors.black,
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        _isAddingActivity
                            ? 'Lưu hoạt động'
                            : '+ Thêm hoạt động cho Day ${_tabController.index + 1}',
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
                        _isDeleteMode
                            ? '✕ Hủy bỏ chế độ xoá'
                            : '− Loại bỏ hoạt động',
                        style: const TextStyle(
                          color: Colors.deepOrange,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: 80,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(2),
                      ),
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
}
