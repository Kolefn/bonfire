import 'dart:math' as math;

import 'package:bonfire/base/custom_widget_builder.dart';
import 'package:bonfire/base/game_component.dart';
import 'package:bonfire/util/camera/camera.dart';
import 'package:bonfire/util/gestures/drag_gesture.dart';
import 'package:bonfire/util/gestures/tap_gesture.dart';
import 'package:bonfire/util/mixins/pointer_detector_mixin.dart';
import 'package:flame/components/component.dart';
import 'package:flame/components/composed_component.dart';
import 'package:flame/components/mixins/has_game_ref.dart';
import 'package:flame/game/base_game.dart';
import 'package:flame/game/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:ordered_set/comparing.dart';
import 'package:ordered_set/ordered_set.dart';

abstract class CustomBaseGame extends BaseGame
    with HasWidgetsOverlay, PointerDetector {
  bool _isPause = false;
  Camera gameCamera = Camera();

  Iterable<GameComponent> get _gesturesComponents => components
      .where((c) =>
          ((c is GameComponent && (c.isVisibleInCamera() || c.isHud())) &&
              ((c is TapGesture && (c as TapGesture).enableTab) ||
                  (c is DragGesture && (c as DragGesture).enableDrag))))
      .cast<GameComponent>();

  Iterable<PointerDetector> get _pointerDetectorComponents =>
      components.where((c) => (c is PointerDetector)).cast();

  void onPointerCancel(PointerCancelEvent event) {
    _pointerDetectorComponents.forEach((c) => c.onPointerCancel(event));
  }

  void onPointerUp(PointerUpEvent event) {
    for (final c in _gesturesComponents) {
      c.handlerPointerUp(
        event.pointer,
        event.localPosition,
      );
    }
    for (final c in _pointerDetectorComponents) {
      c.onPointerUp(event);
    }
  }

  void onPointerMove(PointerMoveEvent event) {
    _gesturesComponents
        .where((element) => element is DragGesture)
        .forEach((element) {
      element.handlerPointerMove(event.pointer, event.localPosition);
    });
    for (final c in _pointerDetectorComponents) {
      c.onPointerMove(event);
    }
  }

  void onPointerDown(PointerDownEvent event) {
    for (final c in _gesturesComponents) {
      c.handlerPointerDown(event.pointer, event.localPosition);
    }

    for (final c in _pointerDetectorComponents) {
      c.onPointerDown(event);
    }
  }

  /// This implementation of render basically calls [renderComponent] for every component, making sure the canvas is reset for each one.
  ///
  /// You can override it further to add more custom behaviour.
  /// Beware of however you are rendering components if not using this; you must be careful to save and restore the canvas to avoid components messing up with each other.
  @override
  void render(Canvas canvas) {
    canvas.save();

    canvas.translate(size.width / 2, size.height / 2);
    canvas.scale(gameCamera.zoom);
    canvas.translate(-gameCamera.position.x, -gameCamera.position.y);

    components.forEach((comp) => renderComponent(canvas, comp));
    canvas.restore();
  }

  /// This renders a single component obeying BaseGame rules.
  ///
  /// It translates the camera unless hud, call the render method and restore the canvas.
  /// This makes sure the canvas is not messed up by one component and all components render independently.
  void renderComponent(Canvas canvas, Component comp) {
    if (!comp.loaded()) {
      return;
    } else if (comp is GameComponent) {
      if (!comp.isHud() && !comp.isVisibleInCamera()) return;
    }

    canvas.save();

    if (comp.isHud()) {
      canvas.translate(gameCamera.position.x, gameCamera.position.y);
      canvas.scale(1 / gameCamera.zoom);
      canvas.translate(-size.width / 2, -size.height / 2);
    }

    comp.render(canvas);
    canvas.restore();
  }

  /// This implementation of update updates every component in the list.
  ///
  /// It also actually adds the components that were added by the [addLater] method, and remove those that are marked for destruction via the [Component.destroy] method.
  /// You can override it further to add more custom behaviour.
  @override
  void update(double t) {
    if (_isPause) return;
    super.update(t);
  }

  void pause() {
    _isPause = true;
  }

  void resume() {
    _isPause = false;
  }

  bool get isGamePaused => _isPause;

  /// This is a hook that comes from the RenderBox to allow recording of render times and statistics.
  @override
  void recordDt(double dt) {
    if (recordFps()) {
      _dts.add(dt);
    }
  }
}
