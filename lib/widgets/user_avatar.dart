///
/// [Author] Alex (https://github.com/AlexV525)
/// [Date] 2019-11-23 18:15
///
import 'package:flutter/material.dart';

import 'package:openjmu/openjmu_route_helper.dart';
import 'package:openjmu/constants/constants.dart';

class UserAvatar extends StatelessWidget {
  const UserAvatar({
    Key key,
    this.uid,
    this.size = 48.0,
    this.timestamp,
    this.radius,
    this.canJump = true,
  })  : assert(radius == null || (radius != null && radius > 0.0)),
        super(key: key);

  final double size;
  final String uid;
  final int timestamp;
  final double radius;
  final bool canJump;

  @override
  Widget build(BuildContext context) {
    final String _uid = uid ?? currentUser.uid;
    return SizedBox.fromSize(
      size: Size.square(size.w),
      child: Tapper(
        child: ClipRRect(
          borderRadius: radius != null
              ? BorderRadius.circular(radius.w)
              : maxBorderRadius,
          child: FadeInImage(
            fadeInDuration: 150.milliseconds,
            placeholder: const AssetImage(R.ASSETS_AVATAR_PLACEHOLDER_PNG),
            image: UserAPI.getAvatarProvider(uid: _uid),
          ),
        ),
        onTap: canJump
            ? () {
                final RouteSettings _routeSettings =
                    ModalRoute.of(context).settings;
                final Map<String, dynamic> _routeArguments =
                    Routes.openjmuUserPage.d(uid: _uid);

                if (_routeSettings is FFRouteSettings) {
                  if (_routeSettings.name != Routes.openjmuUserPage.name ||
                      _routeSettings.arguments.toString() !=
                          _routeArguments.toString()) {
                    navigatorState.pushNamed(
                      Routes.openjmuUserPage.name,
                      arguments: _routeArguments,
                    );
                  }
                } else {
                  navigatorState.pushNamed(
                    Routes.openjmuUserPage.name,
                    arguments: _routeArguments,
                  );
                }
              }
            : null,
      ),
    );
  }
}
