import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class CustomerSupport extends StatefulWidget {
  const CustomerSupport({super.key});

  @override
  State<CustomerSupport> createState() => _CustomerSupportState();
}

class _CustomerSupportState extends State<CustomerSupport> {
  bool _imageLoaded = false;
  bool _imageError = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Krinity"),
   
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Image with shimmer and error fallback
            Stack(
              children: [
                if (!_imageLoaded && !_imageError)
                  Shimmer.fromColors(
                    baseColor: Colors.grey.shade300,
                    highlightColor: Colors.grey.shade100,
                    child: Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                if (_imageError)
                  Container(
                    height: 200,
                    width: double.infinity,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      "Image failed to load",
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    "https://assets.zyrosite.com/cdn-cgi/image/format=auto,w=720,h=212,fit=crop,trim=453.1468531468532;355.2755905511811;815.6643356643356;461.1023622047244/A0xleG2zZeFjLgjV/consumer-cuity-A85eZ8VJzNIpo7Zj.jpeg",
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) {
                        // Delay state update after build
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (!_imageLoaded) {
                            setState(() {
                              _imageLoaded = true;
                            });
                          }
                        });
                        return child;
                      }
                      return const SizedBox.shrink();
                    },
                    errorBuilder: (context, error, stackTrace) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (!_imageError) {
                          setState(() {
                            _imageError = true;
                          });
                        }
                      });
                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              "The Future Farmers's circle",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "Krinity unites those practicing or transitioning to indigenous cow-Based Natural Farming. A digital space to share , learn and grow - blending traditions for chemical-free agriculture.",

              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: Colors.black54),
            ),
            const SizedBox(height: 12),
            const Text(
              "From seed to soil, Krinity empowers farmers to build a mindful, toxib-free India - together.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: Colors.black54),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                print("Notify me");
              },
              icon: const Icon(Icons.notifications_active_outlined),
              label: const Text("Notify me" , style: TextStyle(color: Colors.white),),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 113, 215, 118),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
