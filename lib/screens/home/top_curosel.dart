import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:grocery_app/screens/about/about_screen.dart';
// keep this alias
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:grocery_app/styles/colors.dart';

class TopCurosel extends StatefulWidget {
  TopCurosel({super.key});
  final List<String> imageUrls = [
    'https://res.cloudinary.com/dcuwcjq1f/image/upload/v1759836582/atta_chaki_carousel_zowh5e.jpg',
    'https://res.cloudinary.com/dcuwcjq1f/image/upload/v1759836622/atta_crousel_image_dpennd.jpg',
    'https://res.cloudinary.com/dcuwcjq1f/image/upload/v1759836642/farm_carousel_lcnpp8.jpg',
    'https://res.cloudinary.com/dcuwcjq1f/image/upload/v1759836653/farmer_consultancy_aaosxa.jpg'
  ];

  @override
  State<TopCurosel> createState() => _TopCuroselState();
}

class _TopCuroselState extends State<TopCurosel> {
  final CarouselController _carouselController = CarouselController();
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CarouselSlider(
          items:
              widget.imageUrls.map((url) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    children: [
                      // use Image.network(url) or your asset
                      Image.network(
                        url,
                        fit: BoxFit.cover,
                        width: double.infinity,
                      ),
                      Positioned(
                        bottom: 20,
                        left: 10,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Welcome to Anaad Foods',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) {
                                      return AboutScreen();
                                    },
                                  ),
                                );
                              },
                              style: TextButton.styleFrom(
                                backgroundColor:
                                    AppColors.bottonBackgroundColor,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              child: const Text(
                                "Know Our Mission",
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
          options: CarouselOptions(
            viewportFraction: 1,
            height: MediaQuery.of(context).size.height * 0.25,
            autoPlay: true,
            enlargeCenterPage: true,
            enableInfiniteScroll: true,
            aspectRatio: 16 / 9,
            onPageChanged: (index, reason) {
              setState(() {
                _currentPage = index;
              });
            },
          ),
        ),
        const SizedBox(height: 10),
        AnimatedSmoothIndicator(
          activeIndex: _currentPage,
          count: widget.imageUrls.length,
          effect: ExpandingDotsEffect(
            activeDotColor: AppColors.primaryColor,
            dotHeight: 8,
            dotWidth: 8,
          ),
          onDotClicked: (index) {
            // use the carousel_slider controller's animateToPage
            _carouselController.animateToPage(
              index,
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeInOut,
            );
          },
        ),
      ],
    );
  }
}

extension on CarouselController {
  void animateToPage(
    int index, {
    required Duration duration,
    required Cubic curve,
  }) {}
}
