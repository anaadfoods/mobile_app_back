import 'package:flutter/material.dart';
import 'package:grocery_app/core/theme/app_colors.dart';
import '../common_widgets/short_pull_to_refresh.dart';

class ExampleRefreshScreen extends StatefulWidget {
  const ExampleRefreshScreen({Key? key}) : super(key: key);

  @override
  _ExampleRefreshScreenState createState() => _ExampleRefreshScreenState();
}

class _ExampleRefreshScreenState extends State<ExampleRefreshScreen> {
  final List<String> _items = List.generate(20, (index) => "Item $index");
  Color _headerColor = AppColors.harvestAmber;

  Future<void> _refresh() async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() {
        _items.insert(0, "New Item ${DateTime.now().toIso8601String()}");
        // Change color to demonstrate dynamic styling
        _headerColor =
            _headerColor == AppColors.harvestAmber
                ? AppColors.harvestAmber
                : AppColors.harvestAmber;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Short Pull Demo"),
        backgroundColor: _headerColor,
      ),
      body: Container(
        color: AppColors.parchment,
        child: ShortPullToRefresh(
          headerColor: _headerColor,
          onRefresh: _refresh,
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: _items.length,
            separatorBuilder: (c, i) => const Divider(),
            itemBuilder: (context, index) {
              return Container(
                decoration: BoxDecoration(
                  color: AppColors.parchment,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.charcoal.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _headerColor.withValues(alpha: 0.1),
                    child: Text("${index + 1}"),
                  ),
                  title: Text(
                    _items[index],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text("Pull down to refresh this list"),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
