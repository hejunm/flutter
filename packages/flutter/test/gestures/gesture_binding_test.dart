// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:test/test.dart';

typedef void HandleEventCallback(PointerEvent event);

class TestGestureFlutterBinding extends BindingBase with GestureBinding {
  HandleEventCallback callback;

  @override
  void handleEvent(PointerEvent event, HitTestEntry entry) {
    if (callback != null)
      callback(event);
    super.handleEvent(event, entry);
  }
}

TestGestureFlutterBinding _binding = new TestGestureFlutterBinding();

void ensureTestGestureBinding() {
  if (_binding == null)
    _binding = new TestGestureFlutterBinding();
  assert(GestureBinding.instance != null);
}

void main() {
  setUp(ensureTestGestureBinding);

  test('Pointer tap events', () {
    ui.PointerDataPacket packet = const ui.PointerDataPacket(
      data: const <ui.PointerData>[
        const ui.PointerData(change: ui.PointerChange.down),
        const ui.PointerData(change: ui.PointerChange.up),
      ]
    );

    List<PointerEvent> events = <PointerEvent>[];
    _binding.callback = (PointerEvent event) => events.add(event);

    ui.window.onPointerDataPacket(packet);
    expect(events.length, 2);
    expect(events[0].runtimeType, equals(PointerDownEvent));
    expect(events[1].runtimeType, equals(PointerUpEvent));
  });

  test('Pointer move events', () {
    ui.PointerDataPacket packet = const ui.PointerDataPacket(
      data: const <ui.PointerData>[
        const ui.PointerData(change: ui.PointerChange.down),
        const ui.PointerData(change: ui.PointerChange.move),
        const ui.PointerData(change: ui.PointerChange.up),
      ]
    );

    List<PointerEvent> events = <PointerEvent>[];
    _binding.callback = (PointerEvent event) => events.add(event);

    ui.window.onPointerDataPacket(packet);
    expect(events.length, 3);
    expect(events[0].runtimeType, equals(PointerDownEvent));
    expect(events[1].runtimeType, equals(PointerMoveEvent));
    expect(events[2].runtimeType, equals(PointerUpEvent));
  });

  test('Synthetic move events', () {
    ui.PointerDataPacket packet = const ui.PointerDataPacket(
      data: const <ui.PointerData>[
        const ui.PointerData(
          change: ui.PointerChange.down,
          physicalX: 1.0,
          physicalY: 3.0,
        ),
        const ui.PointerData(
          change: ui.PointerChange.up,
          physicalX: 10.0,
          physicalY: 15.0,
        ),
      ]
    );

    List<PointerEvent> events = <PointerEvent>[];
    _binding.callback = (PointerEvent event) => events.add(event);

    ui.window.onPointerDataPacket(packet);
    expect(events.length, 3);
    expect(events[0].runtimeType, equals(PointerDownEvent));
    expect(events[1].runtimeType, equals(PointerMoveEvent));
    expect(events[1].delta, equals(const Offset(9.0, 12.0)));
    expect(events[2].runtimeType, equals(PointerUpEvent));
  });

  test('Pointer cancel events', () {
    ui.PointerDataPacket packet = const ui.PointerDataPacket(
      data: const <ui.PointerData>[
        const ui.PointerData(change: ui.PointerChange.down),
        const ui.PointerData(change: ui.PointerChange.cancel),
      ]
    );

    List<PointerEvent> events = <PointerEvent>[];
    _binding.callback = (PointerEvent event) => events.add(event);

    ui.window.onPointerDataPacket(packet);
    expect(events.length, 2);
    expect(events[0].runtimeType, equals(PointerDownEvent));
    expect(events[1].runtimeType, equals(PointerCancelEvent));
  });

  test('Can cancel pointers', () {
    ui.PointerDataPacket packet = const ui.PointerDataPacket(
      data: const <ui.PointerData>[
        const ui.PointerData(change: ui.PointerChange.down),
        const ui.PointerData(change: ui.PointerChange.up),
      ]
    );

    List<PointerEvent> events = <PointerEvent>[];
    _binding.callback = (PointerEvent event) {
      events.add(event);
      if (event is PointerDownEvent)
        _binding.cancelPointer(event.pointer);
    };

    ui.window.onPointerDataPacket(packet);
    expect(events.length, 2);
    expect(events[0].runtimeType, equals(PointerDownEvent));
    expect(events[1].runtimeType, equals(PointerCancelEvent));
  });

  test('Can expand add and hover pointers', () {
    ui.PointerDataPacket packet = const ui.PointerDataPacket(
      data: const <ui.PointerData>[
        const ui.PointerData(change: ui.PointerChange.add, device: 24),
        const ui.PointerData(change: ui.PointerChange.hover, device: 24),
        const ui.PointerData(change: ui.PointerChange.remove, device: 24),
        const ui.PointerData(change: ui.PointerChange.hover, device: 24),
      ]
    );

    List<PointerEvent> events = PointerEventConverter.expand(
      packet.data, ui.window.devicePixelRatio).toList();

    expect(events.length, 5);
    expect(events[0].runtimeType, equals(PointerAddedEvent));
    expect(events[1].runtimeType, equals(PointerHoverEvent));
    expect(events[2].runtimeType, equals(PointerRemovedEvent));
    expect(events[3].runtimeType, equals(PointerAddedEvent));
    expect(events[4].runtimeType, equals(PointerHoverEvent));
  });

  test('Synthetic hover and cancel for misplaced down and remove', () {
    ui.PointerDataPacket packet = const ui.PointerDataPacket(
      data: const <ui.PointerData>[
        const ui.PointerData(change: ui.PointerChange.add, device: 25, physicalX: 10.0, physicalY: 10.0),
        const ui.PointerData(change: ui.PointerChange.down, device: 25, physicalX: 15.0, physicalY: 17.0),
        const ui.PointerData(change: ui.PointerChange.remove, device: 25),
      ]
    );

    List<PointerEvent> events = PointerEventConverter.expand(
      packet.data, ui.window.devicePixelRatio).toList();

    expect(events.length, 5);
    expect(events[0].runtimeType, equals(PointerAddedEvent));
    expect(events[1].runtimeType, equals(PointerHoverEvent));
    expect(events[1].delta, equals(const Offset(5.0, 7.0) / ui.window.devicePixelRatio));
    expect(events[2].runtimeType, equals(PointerDownEvent));
    expect(events[3].runtimeType, equals(PointerCancelEvent));
    expect(events[4].runtimeType, equals(PointerRemovedEvent));
  });
}
