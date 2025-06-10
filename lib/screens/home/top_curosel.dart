import 'package:carousel_slider/carousel_options.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';

class TopCurosel extends StatefulWidget {
 TopCurosel({super.key});

  final List<String> imageUrls = [
    'https://assets.zyrosite.com/cdn-cgi/image/format=auto,w=1920,fit=crop/A0xleG2zZeFjLgjV/slidescroll1-mk3vyrjar2sPvOrq.jpeg',
    'https://assets.zyrosite.com/cdn-cgi/image/format=auto,w=1920,fit=crop/A0xleG2zZeFjLgjV/slidescroll4-AQEx4R1bgGux12OX.jpeg',
    'https://assets.zyrosite.com/cdn-cgi/image/format=auto,w=1920,fit=crop/A0xleG2zZeFjLgjV/slidescroll2-YKb3aQpzGGU2ovZg.jpeg',
  ];
  @override
  State<TopCurosel> createState() => _TopCuroselState();
}

class _TopCuroselState extends State<TopCurosel> {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: CarouselSlider(
                items: widget.imageUrls
                    .map((url) => ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            url,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ))
                    .toList(),
                options: CarouselOptions(
                  viewportFraction: 1,
                  
                  height: MediaQuery.of(context).size.height * 0.25,
                  autoPlay: true,
                  enlargeCenterPage: true,
                  enableInfiniteScroll: true,
                  aspectRatio: 16/9,
                ),
              ),

    );
  }
}