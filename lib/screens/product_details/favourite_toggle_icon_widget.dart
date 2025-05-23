import 'package:flutter/material.dart';

class FavoriteToggleIcon extends StatefulWidget {
  final bool favorite;
  final Function onToggle;

  const FavoriteToggleIcon({
    Key? key,
    required this.favorite,
    required this.onToggle,
  }) : super(key: key);

  @override
  _FavoriteToggleIconState createState() => _FavoriteToggleIconState();
}

class _FavoriteToggleIconState extends State<FavoriteToggleIcon> {
  late bool _isFavorite;

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.favorite;
  }

  @override
  void didUpdateWidget(FavoriteToggleIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.favorite != widget.favorite) {
      setState(() {
        _isFavorite = widget.favorite;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        setState(() {
          _isFavorite = !_isFavorite;
        });
        widget.onToggle();
      },
      child: Icon(
        _isFavorite ? Icons.favorite : Icons.favorite_border,
        color: _isFavorite ? Colors.red : Colors.blueGrey,
        size: 30,
      ),
    );
  }
}
