import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../utils/avatar_storage.dart';

class UserAvatar extends StatelessWidget {
  final String? avatarUrl;
  final String initials;
  final double radius;
  final Color? backgroundColor;

  const UserAvatar({
    super.key,
    required this.avatarUrl,
    required this.initials,
    this.radius = 26,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final image = AvatarStorage.imageProvider(avatarUrl);
    final bg = backgroundColor ?? AppColors.primaryOf(context);

    if (image == null) {
      return Container(
        key: ValueKey(initials),
        width: radius * 2,
        height: radius * 2,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: bg,
        ),
        alignment: Alignment.center,
        child: Text(
          initials,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: radius * 0.68,
          ),
        ),
      );
    }

    return Container(
      key: ValueKey(avatarUrl),
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: bg,
      ),
      child: ClipOval(
        child: Image(
          image: image,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Center(
              child: Text(
                initials,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: radius * 0.68,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
