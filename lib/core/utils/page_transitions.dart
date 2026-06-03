import 'package:animations/animations.dart';
import 'package:flutter/material.dart';

/// SharedAxis Z축 화면 전환 PageRoute
/// 부모→자식 화면 관계에 적합한 확대/축소 + 페이드 전환
class SharedAxisPageRoute<T> extends PageRouteBuilder<T> {
  SharedAxisPageRoute({
    required WidgetBuilder builder,
    super.settings,
    SharedAxisTransitionType transitionType = SharedAxisTransitionType.scaled,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) =>
              builder(context),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SharedAxisTransition(
              animation: animation,
              secondaryAnimation: secondaryAnimation,
              transitionType: transitionType,
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 300),
          reverseTransitionDuration: const Duration(milliseconds: 300),
        );
}
