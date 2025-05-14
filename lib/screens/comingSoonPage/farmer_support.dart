import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class FarmerSupport extends StatefulWidget {
  const FarmerSupport({super.key});

  @override
  State<FarmerSupport> createState() => _FarmerSupportState();
}

class _FarmerSupportState extends State<FarmerSupport> {
  bool _imageLoaded = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Granity"),
       
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Stack(
              children: [
                if (!_imageLoaded)
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
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    "https://assets.zyrosite.com/cdn-cgi/image/format=auto,w=1080,h=342,fit=crop,trim=424.6153846153846;359.136690647482;775.3846153846154;460.43165467625903/A0xleG2zZeFjLgjV/consumer-cuity-A85eZ8VJzNIpo7Zj.jpeg",
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) {
                        Future.delayed(Duration.zero, () {
                          if (mounted) setState(() => _imageLoaded = true);
                        });
                        return child;
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              "Because you deserve food that heals, not harms.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "We promise purity, nutrition, and trust — so your family eats clean, lives light, and feels alive every single day.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                print("Notify me");
              },
              icon: const Icon(Icons.notifications_active_outlined),
              label: const Text("Notify me", style: TextStyle(fontSize: 16, color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
