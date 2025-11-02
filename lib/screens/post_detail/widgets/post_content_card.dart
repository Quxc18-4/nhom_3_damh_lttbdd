// =========================================================================
// PostContentCard
// Widget hiển thị nội dung post với photo grid layout, tags và actions
// =========================================================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '/model/post_model.dart';

class PostContentCard extends StatelessWidget {
  /// Dữ liệu bài viết
  final Post post;

  /// Callback khi nhấn like
  final VoidCallback onLike;

  /// Callback khi nhấn comment
  final VoidCallback onComment;

  /// Callback khi nhấn share
  final VoidCallback onShare;

  /// Callback khi nhấn vào avatar hoặc tên tác giả
  final VoidCallback onAuthorTap;

  const PostContentCard({
    Key? key,
    required this.post,
    required this.onLike,
    required this.onComment,
    required this.onShare,
    required this.onAuthorTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final numberFormat = NumberFormat.compact(
      locale: "en_US",
    ); // định dạng số (like/comment count)

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ==========================
          // AUTHOR INFO
          // ==========================
          _buildAuthorHeader(),
          const SizedBox(height: 16),

          // ==========================
          // TITLE
          // ==========================
          Text(
            post.title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          // ==========================
          // CONTENT
          // ==========================
          if (post.content.isNotEmpty) ...[
            Text(
              post.content,
              style: TextStyle(color: Colors.grey[700], fontSize: 15),
            ),
            const SizedBox(height: 16),
          ],

          // ==========================
          // IMAGES (Photo Grid Layout)
          // ==========================
          if (post.imageUrls.isNotEmpty) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: _buildPhotoGrid(),
            ),
            const SizedBox(height: 16),
          ],

          // ==========================
          // TAGS
          // ==========================
          if (post.tags.isNotEmpty) ...[
            _buildTags(),
            const SizedBox(height: 16),
          ],

          const Divider(),

          // ==========================
          // ACTION BUTTONS: Like / Comment / Share
          // ==========================
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildActionButton(
                icon: post.isLikedByUser
                    ? Icons.favorite
                    : Icons.favorite_border,
                label: numberFormat.format(post.likeCount),
                onPressed: onLike,
                color: post.isLikedByUser ? Colors.red : Colors.grey[700],
              ),
              _buildActionButton(
                icon: Icons.chat_bubble_outline,
                label: numberFormat.format(post.commentCount),
                onPressed: onComment,
              ),
              _buildActionButton(
                icon: Icons.share_outlined,
                label: 'Chia sẻ',
                onPressed: onShare,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // AUTHOR HEADER
  // =========================================================================
  Widget _buildAuthorHeader() {
    return GestureDetector(
      onTap: onAuthorTap,
      child: Row(
        children: [
          // Avatar tác giả
          CircleAvatar(
            backgroundImage: post.author.avatarUrl.startsWith('http')
                ? NetworkImage(post.author.avatarUrl)
                : AssetImage(post.author.avatarUrl) as ImageProvider,
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tên tác giả
              Text(
                post.author.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              // Thời gian đăng bài
              Text(
                post.timeAgo,
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // PHOTO GRID - Smart layout dựa trên số lượng ảnh
  // =========================================================================
  Widget _buildPhotoGrid() {
    final images = post.imageUrls;
    final int count = images.length;

    if (count == 0) return const SizedBox.shrink();

    const double mainHeight = 300;

    // LAYOUT 1: 1 ảnh full width
    if (count == 1) {
      return SizedBox(
        height: mainHeight,
        width: double.infinity,
        child: _buildImage(
          images[0],
          height: mainHeight,
          width: double.infinity,
          isTaller: true,
        ),
      );
    }

    // LAYOUT 2: 2 ảnh ngang 50-50
    if (count == 2) {
      return SizedBox(
        height: mainHeight,
        child: Row(
          children: [
            Expanded(
              child: _buildImage(
                images[0],
                height: mainHeight,
                width: double.infinity,
                isTaller: true,
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: _buildImage(
                images[1],
                height: mainHeight,
                width: double.infinity,
                isTaller: true,
              ),
            ),
          ],
        ),
      );
    }

    // LAYOUT 3: 3 ảnh, 2/3 trái + 1/3 phải vertical
    if (count == 3) {
      return SizedBox(
        height: mainHeight,
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: _buildImage(
                images[0],
                height: mainHeight,
                width: double.infinity,
                isTaller: true,
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              flex: 1,
              child: Column(
                children: [
                  Expanded(
                    child: _buildImage(
                      images[1],
                      height: double.infinity,
                      width: double.infinity,
                      isTaller: true,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Expanded(
                    child: _buildImage(
                      images[2],
                      height: double.infinity,
                      width: double.infinity,
                      isTaller: true,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // LAYOUT 4+: Grid 2x2 với overlay "+N"
    final remainingCount = count - 4;

    return SizedBox(
      height: mainHeight,
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: _buildImage(
                    images[0],
                    height: double.infinity,
                    width: double.infinity,
                    isTaller: true,
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: _buildImage(
                    images[1],
                    height: double.infinity,
                    width: double.infinity,
                    isTaller: true,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: _buildImage(
                    images[2],
                    height: double.infinity,
                    width: double.infinity,
                    isTaller: true,
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: _buildImage(
                    images[3],
                    height: double.infinity,
                    width: double.infinity,
                    isTaller: true,
                    overlay: remainingCount > 0
                        ? Container(
                            color: Colors.black54,
                            child: Center(
                              child: Text(
                                '+ $remainingCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          )
                        : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // IMAGE BUILDER
  // Xây dựng 1 ảnh với overlay, loading & error handling
  // =========================================================================
  Widget _buildImage(
    String imageUrl, {
    required double height,
    required double width,
    Widget? overlay,
    required bool isTaller,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Stack(
        fit: isTaller ? StackFit.expand : StackFit.loose,
        children: [
          Image.network(
            imageUrl,
            height: height,
            width: width,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                color: Colors.grey[200],
                child: Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.grey[200],
                child: const Center(
                  child: Icon(Icons.error_outline, color: Colors.red),
                ),
              );
            },
          ),
          if (overlay != null) overlay,
        ],
      ),
    );
  }

  // =========================================================================
  // TAGS
  // =========================================================================
  Widget _buildTags() {
    return Wrap(
      spacing: 8.0,
      children: post.tags
          .map(
            (tag) => Chip(
              label: Text(tag, style: const TextStyle(fontSize: 12)),
              backgroundColor: Colors.grey[200],
              padding: const EdgeInsets.symmetric(horizontal: 4),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          )
          .toList(),
    );
  }

  // =========================================================================
  // ACTION BUTTON BUILDER
  // =========================================================================
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    Color? color,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Icon(icon, color: color ?? Colors.grey[700], size: 20),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(color: color ?? Colors.grey[700])),
          ],
        ),
      ),
    );
  }
}
