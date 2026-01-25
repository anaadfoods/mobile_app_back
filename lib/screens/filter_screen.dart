import 'package:grocery_app/common_widgets/global_import.dart';

class FilterScreen extends StatelessWidget {
  const FilterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: const CloseButton(),
        title: const Text("Filters"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppColors.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Categories",
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppColors.spacingL),
            Container(
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(AppColors.radiusL),
                border: Border.all(
                  color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                ),
              ),
              child: const Column(children: [OptionItem(text: "Eggs")]),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: AppButton(
                label: "Apply Filter",
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OptionItem extends StatefulWidget {
  final String text;

  const OptionItem({super.key, required this.text});

  @override
  _OptionItemState createState() => _OptionItemState();
}

class _OptionItemState extends State<OptionItem> {
  bool _checked = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CheckboxListTile(
      title: Text(widget.text),
      value: _checked,
      activeColor: theme.colorScheme.primary,
      checkboxShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
      ),
      onChanged: (bool? value) {
        setState(() {
          _checked = value ?? false;
        });
      },
    );
  }
}

