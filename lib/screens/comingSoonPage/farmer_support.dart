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
              "India's Toxin-Free Kitchen Tribe.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "Granity is where conscious consumers connect to build toxin-free kitchens and live more mindfully.Share recipes, hacks, and real stories — all rooted in chemical-free agriculture and Indigenous Cow-Based Natural Farming.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
             const SizedBox(height: 12),
            const Text(
              "Not just a community — a rebellion.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
             const SizedBox(height: 12),
            const Text(
              "Where tradition meets technology to reclaim health, plate by plate.",
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
