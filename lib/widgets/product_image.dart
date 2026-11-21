import 'package:flutter/material.dart';

/// Network image with a placeholder for missing or broken URLs.
class ProductImage extends StatelessWidget {
  final String? url;
  final BoxFit fit;
  final double? width;
  final double? height;

  const ProductImage({
    super.key,
    required this.url,
    this.fit = BoxFit.contain,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final placeholder = SizedBox(
      width: width,
      height: height,
      child: Icon(
        url == null ? Icons.image_outlined : Icons.broken_image_outlined,
        size: 40,
        color: Theme.of(context).colorScheme.outline,
      ),
    );
    if (url == null) return placeholder;
    return Image.network(
      url!,
      fit: fit,
      width: width,
      height: height,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return SizedBox(
          width: width,
          height: height,
          child: const Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        );
      },
      errorBuilder: (_, _, _) => placeholder,
    );
  }
}
