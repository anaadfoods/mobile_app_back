import 'package:flutter/material.dart';
import 'package:grocery_app/models/rfp_delivery_model.dart';
import 'package:grocery_app/services/rfp_services.dart';
import 'package:grocery_app/styles/colors.dart';

class ExpandableDeliveryTile extends StatefulWidget {
  final Delivery delivery;

  const ExpandableDeliveryTile({super.key, required this.delivery});

  @override
  State<ExpandableDeliveryTile> createState() => _ExpandableDeliveryTileState();
}

class _ExpandableDeliveryTileState extends State<ExpandableDeliveryTile> {
  late Future<DeliveryDetail> _detailsFuture;
  bool _isExpanded = false;
  bool _hasFetched = false;
  final DeliveryService _service = DeliveryService();

  void _onExpansionChanged(bool isExpanding) {
    setState(() {
      _isExpanded = isExpanding;
    });

    if (isExpanding && !_hasFetched) {
      _detailsFuture = _service.fetchDeliveryDetails(widget.delivery.id);
      _hasFetched = true;
        }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tileColor = _getTileColor(theme, widget.delivery.status);

    return Card(
      elevation: _isExpanded ? 4.0 : 1.0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: tileColor,
      child: ExpansionTile(
        onExpansionChanged: _onExpansionChanged,
        title: Text(widget.delivery.displayLabel, style: theme.textTheme.bodyLarge),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStatusChip(theme, widget.delivery.status),
            const SizedBox(width: 8),
            Icon(
              _isExpanded ? Icons.expand_less : Icons.expand_more,
              color: theme.iconTheme.color,
            ),
          ],
        ),
        children: <Widget>[
          if (_isExpanded) _buildDetailsSection(),
        ],
      ),
    );
  }

  Widget _buildDetailsSection() {
    return FutureBuilder<DeliveryDetail>(
      future: _detailsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(child: Text("Error: ${snapshot.error}")),
          );
        }
        if (!snapshot.hasData) {
          return const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: Text("No details available.")));
        }

        final details = snapshot.data!;
        final planItems = details.items?.planDelivered ?? [];
        final addonItems = details.items?.veggieAddons ?? [];
        final theme = Theme.of(context);

        return Container(
          color: theme.cardColor,
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (planItems.isNotEmpty) _buildItemList("Plan Items", planItems, theme),
              if (addonItems.isNotEmpty) ...[
                const Divider(height: 24),
                _buildItemList("Add-ons", addonItems, theme),
              ],
              if (details.notes != null && details.notes!.isNotEmpty) ...[
                const Divider(height: 24),
                Text("Notes", style: theme.textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(details.notes!, style: theme.textTheme.bodyMedium),
              ]
            ],
          ),
        );
      },
    );
  }

  Widget _buildItemList(String title, List<PlanDelivered> items, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(item.veg?.name ?? 'Unknown Item', style: theme.textTheme.bodyLarge),
                Text(
                  "${item.quantity ?? '0'} kg",
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(ThemeData theme, String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _getStatusColor(theme, status),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: theme.textTheme.labelSmall?.copyWith(color: Colors.white),
      ),
    );
  }

  Color _getStatusColor(ThemeData theme, String status) {
    switch (status.toUpperCase()) {
      case 'DELIVERED':
        return AppColors.success;
      default:
        return theme.disabledColor;
    }
  }

  Color _getTileColor(ThemeData theme, String status) {
    switch (status.toUpperCase()) {
      case 'DELIVERED':
        return AppColors.success.withOpacity(0.1);
      default:
        return theme.cardColor;
    }
  }
}

