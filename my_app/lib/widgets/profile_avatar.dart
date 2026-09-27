import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../core/config/api_config.dart';
import '../theme/app_colors.dart';
import 'design_system.dart';

/// صورة الملف الشخصي مع إطار دائري منسّق.
class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    required this.size,
    this.imageUrl,
    this.localPath,
    this.onTap,
    this.showCameraBadge = false,
    this.badgeSize = 18,
  });

  final double size;
  final String? imageUrl;
  final String? localPath;
  final VoidCallback? onTap;
  final bool showCameraBadge;
  final double badgeSize;

  @override
  Widget build(BuildContext context) {
    final avatar = Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.bottomRight,
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: onTap == null ? null : AppGradients.heroBanner,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: const [BoxShadow(color: AppColors.shadowPurple, blurRadius: 16)],
          ),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
            child: ClipOval(
              child: SizedBox(
                width: size,
                height: size,
                child: _AvatarImage(imageUrl: imageUrl, localPath: localPath, size: size),
              ),
            ),
          ),
        ),
        if (showCameraBadge)
          Material(
            elevation: 4,
            color: AppColors.primary,
            shape: const CircleBorder(),
            child: InkWell(
              onTap: onTap,
              customBorder: const CircleBorder(),
              child: Padding(
                padding: EdgeInsets.all(badgeSize * 0.55),
                child: Icon(Icons.camera_alt_rounded, color: Colors.white, size: badgeSize),
              ),
            ),
          ),
      ],
    );

    if (onTap == null) return avatar;
    return GestureDetector(onTap: onTap, child: avatar);
  }
}

class _AvatarImage extends StatelessWidget {
  const _AvatarImage({required this.imageUrl, required this.localPath, required this.size});

  final String? imageUrl;
  final String? localPath;
  final double size;

  @override
  Widget build(BuildContext context) {
    final placeholder = ColoredBox(
      color: AppColors.indicatorFill,
      child: Icon(Icons.person_rounded, size: size * 0.55, color: AppColors.primary),
    );
    final provider = _resolveProvider();
    if (provider != null) {
      return Image(
        image: provider,
        fit: BoxFit.cover,
        width: size,
        height: size,
        errorBuilder: (_, __, ___) => placeholder,
      );
    }
    return placeholder;
  }

  ImageProvider? _resolveProvider() {
    final path = localPath;
    if (path != null && path.isNotEmpty) {
      if (kIsWeb) return NetworkImage(path);
      // ملف مؤقت قد يكون حُذف — نرجع لرابط الخادم بدل صورة فارغة.
      final file = File(path);
      if (file.existsSync()) return FileImage(file);
    }
    final resolved = ApiConfig.resolveMediaUrl(imageUrl);
    if (resolved != null && resolved.isNotEmpty) {
      return kIsWeb ? NetworkImage(resolved) : CachedNetworkImageProvider(resolved);
    }
    return null;
  }
}
