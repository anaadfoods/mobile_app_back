import 'package:flutter/material.dart';
import 'package:grocery_app/styles/colors.dart';

class DeliveryScreen extends StatelessWidget {
  const DeliveryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildUpcomingDeliveryCard(context),
              const SizedBox(height: 24),
              const Text(
                "Your Past Deliveries",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              // Past Deliveries List
              _buildPastDeliveryTile(
                title: "Nov'25 Week 4 Delivery 2",
                status: "Delivered",
                statusColor: Color(0xFF2E7D32),
                tileColor: const Color(0xFFFFFAF0),
              ),
              _buildPastDeliveryTile(
                title: "Nov'25 Week 4 Delivery 2",
                status: "",
                tileColor: const Color(0xFFFFFAF0),
              ),
              _buildPastDeliveryTile(
                title: "Nov'25 Week 4 Delivery 2",
                status: "",
                tileColor: const Color(0xFFFFFAF0),
              ),
              _buildPastDeliveryTile(
                title: "Nov'25 Week 4 Delivery 2",
                status: "",
                tileColor: const Color(0xFFE6F4E6),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- TOP ORANGE CARD ---
  Widget _buildUpcomingDeliveryCard(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFFFA34F),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Arriving Soon",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10)

                ),
                child: const Text(
                  "Register For RTP",
                  style: TextStyle(
                    color:AppColors.bottonBackgroundColor,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Illustration
          Center(
            child: Image.network(
              "https://cdn-icons-png.flaticon.com/512/859/859270.png",
              height: 100,
            ),
          ),
          const SizedBox(height: 12),
          // Delivery Title
          const Center(
            child: Text(
              "Your Next Delivery",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 1),
          const Center(
            child: Text(
              "Get ready for your next basket",
              style: TextStyle(
                fontSize: 12,
                color: Colors.white70,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Info Chips Row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _infoChip(Icons.calendar_today, "December 01, 2025"),
              const SizedBox(width: 8),
              _textChip("Week 1"),
              const SizedBox(width: 8),
              _textChip("Delivery 1"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.white
        )
      ),
      child: Row(
        children: [
          Icon(icon, color:Colors.white, size: 12),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white ,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _textChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.white
        )
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  // --- PAST DELIVERY ITEM ---
  Widget _buildPastDeliveryTile({
    required String title,
    String? status,
    Color? statusColor,
    Color? tileColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: tileColor ?? Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (status != null && status!.isNotEmpty)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: (statusColor ?? AppColors.primaryColor),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status!,
                  style: TextStyle(
                    color: statusColor ?? Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: Colors.black54),
          ],
        ),
      ),
    );
  }
}
