import 'package:flutter/material.dart';
import 'package:wawa_vansales/ui/widgets/sales_summary_widget.dart';
import 'package:wawa_vansales/ui/widgets/pre_order_summary_widget.dart';

class CombinedSummaryWidget extends StatefulWidget {
  const CombinedSummaryWidget({super.key});

  @override
  State<CombinedSummaryWidget> createState() => _CombinedSummaryWidgetState();
}

class _CombinedSummaryWidgetState extends State<CombinedSummaryWidget> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Carousel for summaries
        SizedBox(
          height: 230, // Increased height for the carousel to prevent overflow
          child: PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            children: const [
              SalesSummaryWidget(),
              PreOrderSummaryWidget(),
            ],
          ),
        ),

        // Page indicators
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildIndicator(0),
            const SizedBox(width: 8),
            _buildIndicator(1),
          ],
        ),
      ],
    );
  }

  Widget _buildIndicator(int index) {
    return GestureDetector(
      onTap: () {
        _pageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      },
      child: Container(
        width: 8,
        height: 8,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _currentIndex == index ? (index == 0 ? Colors.green : Colors.orange) : Colors.grey.shade300,
        ),
      ),
    );
  }
}
