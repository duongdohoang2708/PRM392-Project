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

    return CircleAvatar(
      key: ValueKey(avatarUrl ?? initials),
      radius: radius,
      backgroundColor: backgroundColor ?? AppColors.primary,
      backgroundImage: image,
      child: image == null
          ? Text(
              initials,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: radius * 0.68,
              ),
            )
          : null,
    );
  }
}
