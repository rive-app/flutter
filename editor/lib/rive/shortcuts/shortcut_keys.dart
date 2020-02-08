import 'package:flutter/services.dart';

import '../../platform/platform.dart';

/// Map shortcut key to a list of physical keys.
Map<ShortcutKey, List<PhysicalKeyboardKey>> keyToPhysical = {
  ShortcutKey.comma: [PhysicalKeyboardKey.comma],
  ShortcutKey.period: [
    PhysicalKeyboardKey.period,
    PhysicalKeyboardKey.numpadComma
  ],
  ShortcutKey.alt: [PhysicalKeyboardKey.altLeft, PhysicalKeyboardKey.altRight],
  ShortcutKey.shift: [
    PhysicalKeyboardKey.shiftLeft,
    PhysicalKeyboardKey.shiftRight
  ],
  ShortcutKey.meta: [
    PhysicalKeyboardKey.metaLeft,
    PhysicalKeyboardKey.metaRight
  ],
  ShortcutKey.cmd: [
    PhysicalKeyboardKey.metaLeft,
    PhysicalKeyboardKey.metaRight
  ],
  ShortcutKey.systemCmd: Platform.instance.isMac
      ? [PhysicalKeyboardKey.metaLeft, PhysicalKeyboardKey.metaRight]
      : [PhysicalKeyboardKey.controlLeft, PhysicalKeyboardKey.controlRight],
  ShortcutKey.a: [PhysicalKeyboardKey.keyA],
  ShortcutKey.b: [PhysicalKeyboardKey.keyB],
  ShortcutKey.c: [PhysicalKeyboardKey.keyC],
  ShortcutKey.d: [PhysicalKeyboardKey.keyD],
  ShortcutKey.e: [PhysicalKeyboardKey.keyE],
  ShortcutKey.f: [PhysicalKeyboardKey.keyF],
  ShortcutKey.g: [PhysicalKeyboardKey.keyG],
  ShortcutKey.h: [PhysicalKeyboardKey.keyH],
  ShortcutKey.i: [PhysicalKeyboardKey.keyI],
  ShortcutKey.j: [PhysicalKeyboardKey.keyJ],
  ShortcutKey.k: [PhysicalKeyboardKey.keyK],
  ShortcutKey.l: [PhysicalKeyboardKey.keyL],
  ShortcutKey.m: [PhysicalKeyboardKey.keyM],
  ShortcutKey.n: [PhysicalKeyboardKey.keyN],
  ShortcutKey.o: [PhysicalKeyboardKey.keyO],
  ShortcutKey.p: [PhysicalKeyboardKey.keyP],
  ShortcutKey.q: [PhysicalKeyboardKey.keyQ],
  ShortcutKey.r: [PhysicalKeyboardKey.keyR],
  ShortcutKey.s: [PhysicalKeyboardKey.keyS],
  ShortcutKey.t: [PhysicalKeyboardKey.keyT],
  ShortcutKey.u: [PhysicalKeyboardKey.keyU],
  ShortcutKey.v: [PhysicalKeyboardKey.keyV],
  ShortcutKey.w: [PhysicalKeyboardKey.keyW],
  ShortcutKey.x: [PhysicalKeyboardKey.keyX],
  ShortcutKey.y: [PhysicalKeyboardKey.keyY],
  ShortcutKey.z: [PhysicalKeyboardKey.keyZ],
  ShortcutKey.zero: [PhysicalKeyboardKey.digit0, PhysicalKeyboardKey.numpad0],
  ShortcutKey.one: [PhysicalKeyboardKey.digit1, PhysicalKeyboardKey.numpad1],
  ShortcutKey.two: [PhysicalKeyboardKey.digit2, PhysicalKeyboardKey.numpad2],
  ShortcutKey.three: [PhysicalKeyboardKey.digit3, PhysicalKeyboardKey.numpad3],
  ShortcutKey.four: [PhysicalKeyboardKey.digit4, PhysicalKeyboardKey.numpad4],
  ShortcutKey.five: [PhysicalKeyboardKey.digit5, PhysicalKeyboardKey.numpad5],
  ShortcutKey.six: [PhysicalKeyboardKey.digit6, PhysicalKeyboardKey.numpad6],
  ShortcutKey.seven: [PhysicalKeyboardKey.digit7, PhysicalKeyboardKey.numpad7],
  ShortcutKey.eight: [PhysicalKeyboardKey.digit8, PhysicalKeyboardKey.numpad8],
  ShortcutKey.nine: [PhysicalKeyboardKey.digit9, PhysicalKeyboardKey.numpad9],
  ShortcutKey.backquote: [PhysicalKeyboardKey.backquote],
  ShortcutKey.backspace: [PhysicalKeyboardKey.backspace],
  ShortcutKey.delete: [PhysicalKeyboardKey.delete],
  ShortcutKey.esc: [PhysicalKeyboardKey.escape],
  ShortcutKey.space: [PhysicalKeyboardKey.space],
  ShortcutKey.home: [PhysicalKeyboardKey.home],
  ShortcutKey.end: [PhysicalKeyboardKey.end],
  ShortcutKey.bracketLeft: [PhysicalKeyboardKey.bracketLeft],
  ShortcutKey.bracketRight: [PhysicalKeyboardKey.bracketRight],
  ShortcutKey.slash: [PhysicalKeyboardKey.slash],
  ShortcutKey.backslash: [PhysicalKeyboardKey.backslash],
  ShortcutKey.right: [PhysicalKeyboardKey.arrowRight],
  ShortcutKey.left: [PhysicalKeyboardKey.arrowLeft],
  ShortcutKey.up: [PhysicalKeyboardKey.arrowUp],
  ShortcutKey.down: [PhysicalKeyboardKey.arrowDown],
  ShortcutKey.enter: [
    PhysicalKeyboardKey.enter,
    PhysicalKeyboardKey.numpadEnter
  ],
};

Map<ShortcutKey, String> _keyNames = {
  ShortcutKey.alt: 'alt',
  ShortcutKey.enter: 'enter',
  ShortcutKey.shift: 'shift',
  ShortcutKey.meta: 'meta',
  ShortcutKey.cmd: 'cmd',
  ShortcutKey.a: 'a',
  ShortcutKey.b: 'b',
  ShortcutKey.c: 'c',
  ShortcutKey.d: 'd',
  ShortcutKey.e: 'e',
  ShortcutKey.f: 'f',
  ShortcutKey.g: 'g',
  ShortcutKey.h: 'h',
  ShortcutKey.i: 'i',
  ShortcutKey.j: 'j',
  ShortcutKey.k: 'k',
  ShortcutKey.l: 'l',
  ShortcutKey.m: 'm',
  ShortcutKey.n: 'n',
  ShortcutKey.o: 'o',
  ShortcutKey.p: 'p',
  ShortcutKey.q: 'q',
  ShortcutKey.r: 'r',
  ShortcutKey.s: 's',
  ShortcutKey.t: 't',
  ShortcutKey.u: 'u',
  ShortcutKey.v: 'v',
  ShortcutKey.w: 'w',
  ShortcutKey.x: 'x',
  ShortcutKey.y: 'y',
  ShortcutKey.z: 'z',
  ShortcutKey.zero: '0',
  ShortcutKey.one: '1',
  ShortcutKey.two: '2',
  ShortcutKey.three: '3',
  ShortcutKey.four: '4',
  ShortcutKey.five: '5',
  ShortcutKey.six: '6',
  ShortcutKey.seven: '7',
  ShortcutKey.eight: '8',
  ShortcutKey.nine: '9',
  ShortcutKey.backquote: '`',
  ShortcutKey.backspace: 'backspace',
  ShortcutKey.delete: 'delete',
  ShortcutKey.esc: 'esc',
  ShortcutKey.space: 'space',
  ShortcutKey.home: 'home',
  ShortcutKey.end: 'end',
  ShortcutKey.bracketLeft: '[',
  ShortcutKey.bracketRight: ']',
  ShortcutKey.slash: '/',
  ShortcutKey.backslash: '\\',
  ShortcutKey.right: 'right',
  ShortcutKey.left: 'left',
  ShortcutKey.up: 'up',
  ShortcutKey.down: 'down',
};

String keyname(ShortcutKey key) {
  var name = _keyNames[key];
  if (name != null) {
    return name;
  }
  switch (key) {
    case ShortcutKey.systemCmd:
      return _isMac() ? 'cmd' : 'ctrl';
      break;
    default:
      return null;
  }
}

bool _isMac() {
  return true;
  // return kIsWeb
  //     ? html.window.navigator.appVersion.contains('Mac')
  //     : Platform.isMacOS;
}

enum ShortcutKey {
  alt,
  enter,
  shift,
  meta,
  cmd,
  systemCmd,
  comma,
  period,
  a,
  b,
  c,
  d,
  e,
  f,
  g,
  h,
  i,
  j,
  k,
  l,
  m,
  n,
  o,
  p,
  q,
  r,
  s,
  t,
  u,
  v,
  w,
  x,
  y,
  z,
  zero,
  one,
  two,
  three,
  four,
  five,
  six,
  seven,
  eight,
  nine,
  backquote,
  backspace,
  delete,
  esc,
  space,
  home,
  end,
  bracketLeft,
  bracketRight,
  braceLeft,
  braceRight,
  slash,
  backslash,
  right,
  left,
  up,
  down,
}
