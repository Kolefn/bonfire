import 'dart:math';

import 'package:bonfire/bonfire.dart';
import 'package:flame/animation.dart' as FlameAnimation;
import 'package:flutter/painting.dart';
import 'package:flutter/widgets.dart';

class RotationPlayer extends Player {
  final FlameAnimation.Animation animIdle;
  final FlameAnimation.Animation animRun;
  double speed;
  double momentumFactor;
  double currentRadAngle;
  double _currentMoveRadAngle;
  FlameAnimation.Animation animation;

  RotationPlayer({
    @required Position initPosition,
    @required this.animIdle,
    @required this.animRun,
    this.speed = 150,
    this.momentumFactor = 0.1,
    this.currentRadAngle = -1.55,
    double width = 32,
    double height = 32,
    double life = 100,
    Collision collision,
  }) : super(
            initPosition: initPosition,
            width: width,
            height: height,
            life: life,
            collision: collision) {
    this.animation = animIdle;
    _currentMoveRadAngle = currentRadAngle;
  }

  @override
  void joystickChangeDirectional(JoystickDirectionalEvent event) {
    if (event.directional != JoystickMoveDirectional.IDLE &&
        !isDead &&
        event.radAngle != 0.0) {
      currentRadAngle = event.radAngle;
      this.animation = animRun;
    } else {
      this.animation = animIdle;
    }
    _currentMoveRadAngle += (currentRadAngle - _currentMoveRadAngle) *
        (event.intensity * momentumFactor);
    super.joystickChangeDirectional(event);
  }

  @override
  void update(double dt) {
    if (speed > 0 && !isDead) {
      moveFromAngle(speed, _currentMoveRadAngle);
    }
    animation?.update(dt);
    super.update(dt);
  }

  @override
  void render(Canvas canvas) {
    canvas.save();
    canvas.translate(position.center.dx, position.center.dy);
    canvas.rotate(currentRadAngle == 0.0 ? 0.0 : currentRadAngle + (pi / 2));
    canvas.translate(-position.center.dx, -position.center.dy);
    _renderAnimation(canvas);
    canvas.restore();
  }

  void _renderAnimation(Canvas canvas) {
    if (animation == null || position == null) return;
    if (animation.loaded()) {
      animation.getSprite().renderRect(canvas, position);
    }
  }
}
