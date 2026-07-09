import 'dart:io';
import 'package:flutter/material.dart';

/// Widget hiển thị ảnh thông minh:
/// - Nếu [imageUrl] bắt đầu bằng "http" → dùng Image.network()
/// - Nếu [imageUrl] là đường dẫn file local → dùng Image.file()
/// - Nếu rỗng hoặc lỗi → hiển thị [placeholder]
class SmartImage extends StatelessWidget {
  final String imageUrl;
  final double? height;
  final double? width;
  final BoxFit fit;
  final Widget? placeholder;
  final BorderRadius? borderRadius;

  const SmartImage({
    super.key,
    required this.imageUrl,
    this.height,
    this.width,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.borderRadius,
  });

  bool get _isNetworkUrl =>
      imageUrl.startsWith('http://') || imageUrl.startsWith('https://');

  Widget _defaultPlaceholder() => Container(
        height: height,
        width: width,
        color: const Color(0xFFF3F5F4),
        child: const Center(
          child: Icon(
            Icons.image_outlined,
            size: 40,
            color: Color(0xFF6B7280),
          ),
        ),
      );

  Widget _errorWidget() => Container(
        height: height,
        width: width,
        color: const Color(0xFFF3F5F4),
        child: const Center(
          child: Icon(
            Icons.broken_image_outlined,
            size: 40,
            color: Color(0xFF6B7280),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) {
      return placeholder ?? _defaultPlaceholder();
    }

    Widget image;

    if (_isNetworkUrl) {
      image = Image.network(
        imageUrl,
        height: height,
        width: width,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => _errorWidget(),
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Container(
            height: height,
            width: width,
            color: const Color(0xFFF3F5F4),
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        },
      );
    } else {
      // Local file path
      final file = File(imageUrl);
      if (!file.existsSync()) {
        return _errorWidget();
      }
      image = Image.file(
        file,
        height: height,
        width: width,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => _errorWidget(),
      );
    }

    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: image);
    }
    return image;
  }
}
