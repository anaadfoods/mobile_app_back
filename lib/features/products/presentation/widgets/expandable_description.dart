import 'package:grocery_app/common_widgets/global_import.dart';

class ExpandableDescription extends StatefulWidget {
  final String text;
  const ExpandableDescription({super.key, required this.text});

  @override
  _ExpandableDescriptionState createState() => _ExpandableDescriptionState();
}

class _ExpandableDescriptionState extends State<ExpandableDescription> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          child: Text(
            widget.text.trim(),
            style: TextStyle(
              color: isDark
                  ? AppColors.parchment.withValues(alpha: 0.8)
                  : AppColors.charcoal87,
              fontSize: 14,
              height: 1.6,
            ),
            textAlign: TextAlign.justify,
            maxLines: _isExpanded ? null : 3,
            overflow: _isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          child: Text(
            _isExpanded ? "Show Less" : "Read More",
            style: TextStyle(
              color: isDark ? AppColors.harvestAmber : AppColors.rawEarth,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
