import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:rive_api/src/plumber.dart';

typedef SubscribeCallback<T> = void Function(T);

mixin Subscriptions {
  List<StreamSubscription> subscriptions;

  @mustCallSuper
  void dispose() {
    subscriptions.forEach((sub) => sub.cancel());
    subscriptions.clear();
  }

  void subscribe<T>(SubscribeCallback<T> action) {
    if (subscriptions == null) {
      subscriptions = [];
    }
    var stream = Plumber().getStream<T>();
    var subscription = stream.listen(action);
    subscriptions.add(subscription);
  }
}
