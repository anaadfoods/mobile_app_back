import 'package:grocery_app/common_widgets/global_import.dart';

class ProductImageZoomViewer extends StatefulWidget {
  final String imageUrl;

  const ProductImageZoomViewer({
    super.key,
    required this.imageUrl,
  });

  @override
  State<ProductImageZoomViewer> createState() => _ProductImageZoomViewerState();
}

class _ProductImageZoomViewerState extends State<ProductImageZoomViewer> {
  final TransformationController _transformationController =
      TransformationController();
  final GlobalKey _viewerKey = GlobalKey();

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  void _resetZoom() {
    _transformationController.value = Matrix4.identity();
  }

  Rect _visibleRect(Size viewportSize) {
    final matrix = _transformationController.value;
    final scale = matrix.getMaxScaleOnAxis();
    final translation = matrix.getTranslation();

    final visibleWidth = viewportSize.width / scale;
    final visibleHeight = viewportSize.height / scale;
    final left = (-translation.x / scale).clamp(0.0, viewportSize.width - visibleWidth);
    final top = (-translation.y / scale).clamp(0.0, viewportSize.height - visibleHeight);

    return Rect.fromLTWH(left, top, visibleWidth, visibleHeight);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      backgroundColor: Colors.black.withValues(alpha: 0.96),
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final thumbnailWidth = constraints.maxWidth * 0.32;
            final thumbnailHeight = 110.0;

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close, color: Colors.white),
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Pinch to zoom',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: _resetZoom,
                        child: const Text(
                          'Reset',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Center(
                    child: SizedBox.expand(
                      child: InteractiveViewer(
                        key: _viewerKey,
                        transformationController: _transformationController,
                        minScale: 1,
                        maxScale: 4,
                        panEnabled: true,
                        scaleEnabled: true,
                        boundaryMargin: const EdgeInsets.all(80),
                        onInteractionUpdate: (_) {
                          if (mounted) setState(() {});
                        },
                        child: CachedNetworkImage(
                          imageUrl: widget.imageUrl,
                          fit: BoxFit.contain,
                          width: double.infinity,
                          height: double.infinity,
                          placeholder: (context, url) => const Center(
                            child: CircularProgressIndicator(color: Colors.white),
                          ),
                          errorWidget: (context, url, error) => const Center(
                            child: Icon(
                              Icons.broken_image_outlined,
                              color: Colors.white70,
                              size: 56,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Column(
                    children: [
                      const Text(
                        'Zoom overview',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        width: thumbnailWidth,
                        height: thumbnailHeight,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(13),
                          child: LayoutBuilder(
                            builder: (context, thumbConstraints) {
                              final thumbSize = Size(
                                thumbConstraints.maxWidth,
                                thumbConstraints.maxHeight,
                              );
                              final visibleRect = _visibleRect(thumbSize);

                              return Stack(
                                children: [
                                  Positioned.fill(
                                    child: CachedNetworkImage(
                                      imageUrl: widget.imageUrl,
                                      fit: BoxFit.contain,
                                      placeholder: (context, url) => Container(
                                        color: Colors.white.withValues(alpha: 0.04),
                                      ),
                                      errorWidget: (context, url, error) => const Center(
                                        child: Icon(
                                          Icons.broken_image_outlined,
                                          color: Colors.white54,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    left: visibleRect.left,
                                    top: visibleRect.top,
                                    width: visibleRect.width,
                                    height: visibleRect.height,
                                    child: IgnorePointer(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: Colors.amberAccent,
                                            width: 2,
                                          ),
                                          color: Colors.amberAccent.withValues(alpha: 0.12),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Drag the image to inspect different areas.',
                        style: TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
