import 'package:flutter/material.dart';
import 'package:grocery_app/models/rfp_delivery_model.dart';
import 'package:grocery_app/screens/RFP/expandable_delivery_tile.dart';
import 'package:grocery_app/services/rfp_services.dart';

class DeliveryScreen extends StatefulWidget {
  const DeliveryScreen({super.key});

  @override
  State<DeliveryScreen> createState() => _DeliveryScreenState();
}

class _DeliveryScreenState extends State<DeliveryScreen> {
  final DeliveryService _deliveryService = DeliveryService();
  late Future<List<Delivery>> _deliveriesFuture;

  @override
  void initState() {
    super.initState();
    _deliveriesFuture = _deliveryService.fetchDeliveries();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Deliveries'),
      ),
      body: SafeArea(
        child: FutureBuilder<List<Delivery>>(
          future: _deliveriesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text("Error: ${snapshot.error}"),
                ),
              );
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text("No deliveries found."));
            }

            final deliveries = snapshot.data!;
            final upcomingDelivery = deliveries.first;
            final pastDeliveries = deliveries.toList();

            return RefreshIndicator(
              onRefresh: () async {
                setState(() {
                  _deliveriesFuture = _deliveryService.fetchDeliveries();
                });
              },
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildUpcomingDeliveryCard(context, upcomingDelivery),
                    const SizedBox(height: 24),
                    Text(
                      "Your Past Deliveries",
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: pastDeliveries.length,
                      itemBuilder: (context, index) {
                        final delivery = pastDeliveries[index];
                        return ExpandableDeliveryTile(delivery: delivery);
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildUpcomingDeliveryCard(BuildContext context, Delivery delivery) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colorScheme.secondary,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Most Recent Delivery",
                style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSecondary),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                decoration: BoxDecoration(
                    color: colorScheme.onSecondary,
                    borderRadius: BorderRadius.circular(10)),
                child: Text(
                  "Register For RTP",
                  style: theme.textTheme.labelSmall?.copyWith(color: colorScheme.secondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Center(
            child: Image.network(
              "https://cdn-icons-png.flaticon.com/512/859/859270.png",
              height: 100,
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              "Your Next Delivery",
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(color: colorScheme.onSecondary),
            ),
          ),
          Center(
            child: Text(
              "Get Ready for Your next basket",
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(color: colorScheme.onSecondary),
            ),
          ),
          const SizedBox(height: 1),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
            decoration: BoxDecoration(
              color: colorScheme.onSecondary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                "Soon!",
                style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSecondary),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

