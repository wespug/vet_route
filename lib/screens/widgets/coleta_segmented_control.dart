import 'package:flutter/material.dart';

class ColetaSegmentedControl extends StatelessWidget {
  final TabController tabController;

  const ColetaSegmentedControl({super.key, required this.tabController});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFE3E3E8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: tabController,
        isScrollable: false,
        tabAlignment: TabAlignment.fill,
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(9),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        labelColor: const Color(0xFF1C1C1E),
        unselectedLabelColor: const Color(0xFF636366),
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
        tabs: const [
          Tab(
            height: 38,
            child: Align(alignment: Alignment.center, child: Text("Em Aberto")),
          ),
          Tab(
            height: 38,
            child: Align(
              alignment: Alignment.center,
              child: Text("Finalizados & Recusados"),
            ),
          ),
        ],
      ),
    );
  }
}
