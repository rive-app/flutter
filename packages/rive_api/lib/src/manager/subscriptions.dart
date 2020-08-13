import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:rive_api/plumber.dart';

typedef SubscribeCallback<T> = void Function(T);

mixin Subscriptions {
  Set<StreamSubscription> subscriptions;

  @mustCallSuper
  void dispose() {
    subscriptions.forEach((sub) => sub.cancel());
    subscriptions.clear();
  }

  StreamSubscription<T> subscribe<T>(SubscribeCallback<T> action, [int id]) {
    subscriptions ??= {};
    var stream = Plumber().getStream<T>(id);
    var subscription = stream.listen(action);
    subscriptions.add(subscription);
    return subscription;
  }

  void removeSubscription(StreamSubscription sub) {
    subscriptions.remove(sub);
    sub.cancel();
  }
}
