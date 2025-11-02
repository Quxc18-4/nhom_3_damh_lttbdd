// File: screens/trip_planner/widget/trip_planner_widgets.dart

import 'package:flutter/material.dart';
// Cập nhật đường dẫn model
import 'package:nhom_3_damh_lttbdd/model/activity.dart';

// === WIDGET 1: FORM THÊM HOẠT ĐỘNG ===
class AddActivityForm extends StatelessWidget {
  final int currentDay;
  final TextEditingController timeController;
  final TextEditingController titleController;
  final TextEditingController detailController;
  final VoidCallback onCancel;
  final VoidCallback onAdd;

  const AddActivityForm({
    Key? key,
    required this.currentDay,
    required this.timeController,
    required this.titleController,
    required this.detailController,
    required this.onCancel,
    required this.onAdd,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
            "Thêm hoạt động cho Ngày $currentDay",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: timeController,
            decoration: InputDecoration(
              hintText: "Thời gian (hh:mm)",
              filled: true,
              fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
            ),
            keyboardType: TextInputType.datetime,
          ),
          const SizedBox(height: 10),
          TextField(
            controller: titleController,
            decoration: InputDecoration(
              hintText: "Tên hoạt động",
              filled: true,
              fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: detailController,
            maxLines: 3,
            minLines: 1,
            decoration: InputDecoration(
              hintText: "Chi tiết (Địa điểm, ghi chú, ...)",
              filled: true,
              fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
            ),
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: onCancel,
                child: const Text("Hủy", style: TextStyle(color: Colors.grey)),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: onAdd,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text("Thêm"),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// === WIDGET 2: ITEM HOẠT ĐỘNG (DẠNG LIST TILE) ===
class ActivityListItem extends StatelessWidget {
  final Activity activity;
  final bool isDeleteMode;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const ActivityListItem({
    Key? key,
    required this.activity,
    required this.isDeleteMode,
    required this.onTap,
    required this.onRemove,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: activity.color.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Icon(activity.icon, size: 22, color: activity.color),
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
        trailing: isDeleteMode
            ? GestureDetector(
                onTap: onRemove,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.remove,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
              )
            : null,
      ),
    );
  }
}

// === WIDGET 3: ITEM HOẠT ĐỘNG (DẠNG CAPSULE) ===
class ActivityCapsule extends StatelessWidget {
  final Activity activity;
  final Color accentColor;
  final VoidCallback onTap;

  const ActivityCapsule({
    Key? key,
    required this.activity,
    required this.accentColor,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (activity.time.isEmpty) return const SizedBox.shrink();

    return GestureDetector(
      onTap: onTap,
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
            Container(
              width: 44,
              height: 44,
              margin: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: activity.color.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(activity.icon, size: 22, color: Colors.white),
              ),
            ),
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
}

// === WIDGET 4: CỘT HIỂN THỊ NGÀY ===
class DayColumn extends StatelessWidget {
  final int day;
  final String date;
  final Color color;

  const DayColumn({
    Key? key,
    required this.day,
    required this.date,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
}

// === WIDGET 5: THẺ TÓM TẮT KẾ HOẠCH (DÙNG TRONG POPUP) ===
class DayPlanSummaryCard extends StatelessWidget {
  final int dayIndex;
  final String date;
  final Color mainColor;
  final Color accentColor;
  final List<Activity> activities;
  final VoidCallback onViewAll; // Callback khi nhấn "Xem tất cả"

  const DayPlanSummaryCard({
    Key? key,
    required this.dayIndex,
    required this.date,
    required this.mainColor,
    required this.accentColor,
    required this.activities,
    required this.onViewAll,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const int limit = 5;
    final isOverLimit = activities.length > limit;
    final limitedActivities = isOverLimit
        ? activities.sublist(0, limit)
        : activities;

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DayColumn(day: dayIndex + 1, date: date, color: mainColor),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: mainColor.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...limitedActivities
                        .map(
                          (activity) => ActivityCapsule(
                            activity: activity,
                            accentColor: accentColor,
                            onTap: () {
                              /* (Trong popup, có thể không cần tap) */
                            },
                          ),
                        )
                        .toList(),
                    if (isOverLimit)
                      Padding(
                        padding: const EdgeInsets.only(
                          top: 4.0,
                          bottom: 4.0,
                          left: 10,
                        ),
                        child: GestureDetector(
                          onTap: onViewAll,
                          child: const Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: 'Xem tất cả hoạt động ',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                                WidgetSpan(
                                  child: Icon(
                                    Icons.arrow_forward_ios,
                                    size: 14,
                                    color: Colors.blue,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    if (activities.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          "Chưa có hoạt động nào.",
                          style: TextStyle(color: Colors.grey),
                        ),
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
}
