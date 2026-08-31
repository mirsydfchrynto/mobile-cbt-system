import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:okey_bimbel/core/theme/app_colors.dart';

class SafeImageWidget extends StatelessWidget {
  final String? imageSource;
  final double? height;
  final double? width;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;

  const SafeImageWidget({
    super.key,
    required this.imageSource,
    this.height,
    this.width,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (imageSource == null || imageSource!.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    final src = imageSource!.trim();
    Widget imageContent;

    if (src.startsWith('http://') || src.startsWith('https://')) {
      // Network Image
      imageContent = Image.network(
        src,
        height: height,
        width: width,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => _buildErrorWidget(),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return SizedBox(
            height: height ?? 100,
            width: width ?? double.infinity,
            child: const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
              ),
            ),
          );
        },
      );
    } else {
      // Base64 Image
      try {
        String cleanBase64 = src;
        if (cleanBase64.contains(',')) {
          cleanBase64 = cleanBase64.split(',').last;
        }
        cleanBase64 = cleanBase64.replaceAll(RegExp(r'\s+'), '');
        final Uint8List bytes = base64Decode(cleanBase64);

        imageContent = Image.memory(
          bytes,
          height: height,
          width: width,
          fit: fit,
          gaplessPlayback: true,
          errorBuilder: (context, error, stackTrace) => _buildErrorWidget(),
        );
      } catch (e) {
        imageContent = _buildErrorWidget();
      }
    }

    Widget result = imageContent;
    if (borderRadius != null) {
      result = ClipRRect(borderRadius: borderRadius!, child: result);
    }

    if (onTap != null) {
      result = GestureDetector(onTap: onTap, child: result);
    }

    return result;
  }

  Widget _buildErrorWidget() {
    return Container(
      height: height ?? 100,
      width: width ?? double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: borderRadius ?? BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.imageOff, size: 24, color: Colors.grey.shade400),
            const SizedBox(height: 4),
            Text(
              "Gambar tidak dapat dimuat",
              style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
