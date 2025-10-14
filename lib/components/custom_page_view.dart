// components/custom_page_view.dart
import 'package:flutter/material.dart';

import '../theme/theme.dart';

class CustomPageView extends StatefulWidget {
  final List<String> pageTitles;
  final List<Widget> pages;
  final ValueChanged<int>? onPageChanged;
  final VoidCallback? onFinish;

  const CustomPageView({
    super.key,
    required this.pageTitles,
    required this.pages,
    this.onPageChanged,
    this.onFinish,
  });

  @override
  State<CustomPageView> createState() => _CustomPageViewState();
}

class _CustomPageViewState extends State<CustomPageView> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Progress Indicator
        LinearProgressIndicator(
          value: (_currentPage + 1) / widget.pageTitles.length,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(kSecondaryColor), // Ganti dengan warna tema Anda
          minHeight: 6,
        ),
        const SizedBox(height: 16),

        // Page Content
        Expanded(
          child: PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
              if (widget.onPageChanged != null) {
                widget.onPageChanged!(index);
              }
            },
            children: widget.pages,
          ),
        ),

        // Navigation Buttons
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          child: Row(
            children: [
              // Previous Button
              if (_currentPage > 0)
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white, // Ganti dengan warna tema Anda
                      side: const BorderSide(color: kSecondaryColor), // Ganti dengan warna tema Anda
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: () {
                      _pageController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    child: Text(
                      "SEBELUMNYA",
                      style: secondaryTextStyle.copyWith(
                        fontSize: 14,
                        fontWeight: bold
                      )
                    ),
                  ),
                ),

              if (_currentPage > 0) const SizedBox(width: 16),

              // Next/Finish Button
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kSecondaryColor, // Ganti dengan warna tema Anda
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () {
                    if (_currentPage < widget.pageTitles.length - 1) {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    } else {
                      if (widget.onFinish != null) {
                        widget.onFinish!();
                      }
                    }
                  },
                  child: Text(
                    _currentPage == widget.pageTitles.length - 1
                        ? "SELESAI"
                        : "SELANJUTNYA",
                    style: whiteTextStyle.copyWith(
                      fontSize: 14,
                      fontWeight: bold
                    )
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}