// File: screens/admin_only/widget/place_approval_widgets.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

/// Widget hiển thị danh sách các địa điểm chờ duyệt
class PendingPlacesList extends StatelessWidget {
  final Stream<QuerySnapshot> stream;
  final Function(DocumentSnapshot) onApprove;
  final Function(String) onReject;

  const PendingPlacesList({
    Key? key,
    required this.stream,
    required this.onApprove,
    required this.onReject,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Lỗi: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(
              'Không có địa điểm nào chờ duyệt.',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          );
        }

        final submissions = snapshot.data!.docs;
        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: submissions.length,
          itemBuilder: (context, index) {
            final submission = submissions[index];
            return PlaceSubmissionCard(
              submission: submission,
              onApprove: () => onApprove(submission),
              onReject: () => onReject(submission.id),
            );
          },
        );
      },
    );
  }
}

/// Widget hiển thị thẻ của một địa điểm chờ duyệt
class PlaceSubmissionCard extends StatelessWidget {
  final DocumentSnapshot submission;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const PlaceSubmissionCard({
    Key? key,
    required this.submission,
    required this.onApprove,
    required this.onReject,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final data = submission.data() as Map<String, dynamic>? ?? {};
    final placeData = data['placeData'] as Map<String, dynamic>? ?? {};
    final location = placeData['location'] as Map<String, dynamic>? ?? {};
    final name = placeData['name'] ?? 'Chưa có tên';
    final fullAddress = location['fullAddress'] ?? 'Chưa có địa chỉ';
    final description = placeData['description'] ?? '';
    final createdDate = (data['submittedAt'] as Timestamp?)?.toDate();

    String? imageUrl;
    final images = placeData['images'];
    if (images is List && images.isNotEmpty) {
      imageUrl = images[0] as String?;
    } else if (images is Map && images.isNotEmpty) {
      imageUrl = images.values.first as String?;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (imageUrl != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              child: Image.network(
                imageUrl,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 180,
                    color: Colors.grey[300],
                    child: const Icon(Icons.image_not_supported, size: 60),
                  );
                },
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        fullAddress,
                        style: TextStyle(color: Colors.grey[700], fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                if (description.isNotEmpty)
                  Text(
                    description,
                    style: TextStyle(color: Colors.grey[800], fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 8),
                if (createdDate != null)
                  Text(
                    'Gửi lúc: ${DateFormat('dd/MM/yyyy HH:mm').format(createdDate)}',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text('Từ chối'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
                      onPressed: onReject,
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Duyệt'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: onApprove,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
