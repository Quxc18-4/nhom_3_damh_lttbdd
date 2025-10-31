import 'package:flutter/material.dart';

class SliverTabHeader extends SliverPersistentHeaderDelegate {
  final TabController controller;
  SliverTabHeader(this.controller);

  @override
  double get minExtent => kTextTabBarHeight;

  @override
  double get maxExtent => kTextTabBarHeight;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: controller,
        tabs: const [
          Tab(text: 'Dòng thời gian'),
          Tab(text: 'Giới thiệu'),
          Tab(text: 'Album'),
          Tab(text: 'Theo dõi'),
        ],
        labelColor: Colors.black,
        unselectedLabelColor: Colors.grey,
        indicatorColor: Colors.black,
      ),
    );
  }

  @override
  bool shouldRebuild(covariant SliverTabHeader oldDelegate) => false;
}
