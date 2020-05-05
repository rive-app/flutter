import 'dart:collection';

import 'package:core/debounce.dart';
import 'package:flutter/scheduler.dart';

HashSet<DebounceCallback> _frameDebounce = HashSet<DebounceCallback>();

/// A version of debounce that specifically callsback on the next frame. This is
/// usefull when you want to debounce a call that can happen many times on a
/// single frame but want to ensure that it gets processed before the next frame
/// is drawn to prevent flashing.
bool _scheduled = false;
void cancelFrameDebounce(DebounceCallback callback) {
  _frameDebounce.remove(callback);
}

void frameDebounce(DebounceCallback callback) {
  if (_frameDebounce.add(callback) && !_scheduled) {
    _scheduled = true;
    SchedulerBinding.instance.endOfFrame.then(_debounceFrameCallbacks);
  }
}

void _debounceFrameCallbacks(void _) {
  _scheduled = false;
  var bounce = List<DebounceCallback>.from(_frameDebounce);
  _frameDebounce.clear();
  for (final cb in bounce) {
    cb();
  }
}
