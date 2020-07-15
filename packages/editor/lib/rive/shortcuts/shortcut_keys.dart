import 'package:flutter/services.dart';
import 'package:rive_editor/platform/platform.dart';

/// Map shortcut key to a list of physical keys.
Map<ShortcutKey, Set<PhysicalKeyboardKey>> keyToPhysical = {
  ShortcutKey.comma: {PhysicalKeyboardKey.comma},
  ShortcutKey.period: {
    PhysicalKeyboardKey.period,
    PhysicalKeyboardKey.numpadComma
  },
  ShortcutKey.alt: {PhysicalKeyboardKey.altLeft, PhysicalKeyboardKey.altRight},
  ShortcutKey.shift: {
    PhysicalKeyboardKey.shiftLeft,
    PhysicalKeyboardKey.shiftRight
  },
  ShortcutKey.meta: {
    PhysicalKeyboardKey.metaLeft,
    PhysicalKeyboardKey.metaRight
  },
  ShortcutKey.ctrl: {
    PhysicalKeyboardKey.controlLeft,
    PhysicalKeyboardKey.controlRight
  },
  ShortcutKey.systemCmd: Platform.instance.isMac
      ? {PhysicalKeyboardKey.metaLeft, PhysicalKeyboardKey.metaRight}
      : {PhysicalKeyboardKey.controlLeft, PhysicalKeyboardKey.controlRight},
  ShortcutKey.a: {PhysicalKeyboardKey.keyA},
  ShortcutKey.b: {PhysicalKeyboardKey.keyB},
  ShortcutKey.c: {PhysicalKeyboardKey.keyC},
  ShortcutKey.d: {PhysicalKeyboardKey.keyD},
  ShortcutKey.e: {PhysicalKeyboardKey.keyE},
  ShortcutKey.f: {PhysicalKeyboardKey.keyF},
  ShortcutKey.g: {PhysicalKeyboardKey.keyG},
  ShortcutKey.h: {PhysicalKeyboardKey.keyH},
  ShortcutKey.i: {PhysicalKeyboardKey.keyI},
  ShortcutKey.j: {PhysicalKeyboardKey.keyJ},
  ShortcutKey.k: {PhysicalKeyboardKey.keyK},
  ShortcutKey.l: {PhysicalKeyboardKey.keyL},
  ShortcutKey.m: {PhysicalKeyboardKey.keyM},
  ShortcutKey.n: {PhysicalKeyboardKey.keyN},
  ShortcutKey.o: {PhysicalKeyboardKey.keyO},
  ShortcutKey.p: {PhysicalKeyboardKey.keyP},
  ShortcutKey.q: {PhysicalKeyboardKey.keyQ},
  ShortcutKey.r: {PhysicalKeyboardKey.keyR},
  ShortcutKey.s: {PhysicalKeyboardKey.keyS},
  ShortcutKey.t: {PhysicalKeyboardKey.keyT},
  ShortcutKey.u: {PhysicalKeyboardKey.keyU},
  ShortcutKey.v: {PhysicalKeyboardKey.keyV},
  ShortcutKey.w: {PhysicalKeyboardKey.keyW},
  ShortcutKey.x: {PhysicalKeyboardKey.keyX},
  ShortcutKey.y: {PhysicalKeyboardKey.keyY},
  ShortcutKey.z: {PhysicalKeyboardKey.keyZ},
  ShortcutKey.zero: {PhysicalKeyboardKey.digit0, PhysicalKeyboardKey.numpad0},
  ShortcutKey.one: {PhysicalKeyboardKey.digit1, PhysicalKeyboardKey.numpad1},
  ShortcutKey.two: {PhysicalKeyboardKey.digit2, PhysicalKeyboardKey.numpad2},
  ShortcutKey.three: {PhysicalKeyboardKey.digit3, PhysicalKeyboardKey.numpad3},
  ShortcutKey.four: {PhysicalKeyboardKey.digit4, PhysicalKeyboardKey.numpad4},
  ShortcutKey.five: {PhysicalKeyboardKey.digit5, PhysicalKeyboardKey.numpad5},
  ShortcutKey.six: {PhysicalKeyboardKey.digit6, PhysicalKeyboardKey.numpad6},
  ShortcutKey.seven: {PhysicalKeyboardKey.digit7, PhysicalKeyboardKey.numpad7},
  ShortcutKey.eight: {PhysicalKeyboardKey.digit8, PhysicalKeyboardKey.numpad8},
  ShortcutKey.nine: {PhysicalKeyboardKey.digit9, PhysicalKeyboardKey.numpad9},
  ShortcutKey.backquote: {PhysicalKeyboardKey.backquote},
  ShortcutKey.backspace: {PhysicalKeyboardKey.backspace},
  ShortcutKey.delete: {PhysicalKeyboardKey.delete},
  ShortcutKey.esc: {PhysicalKeyboardKey.escape},
  ShortcutKey.space: {PhysicalKeyboardKey.space},
  ShortcutKey.home: {PhysicalKeyboardKey.home},
  ShortcutKey.end: {PhysicalKeyboardKey.end},
  ShortcutKey.bracketLeft: {PhysicalKeyboardKey.bracketLeft},
  ShortcutKey.bracketRight: {PhysicalKeyboardKey.bracketRight},
  ShortcutKey.slash: {PhysicalKeyboardKey.slash},
  ShortcutKey.backslash: {PhysicalKeyboardKey.backslash},
  ShortcutKey.right: {PhysicalKeyboardKey.arrowRight},
  ShortcutKey.left: {PhysicalKeyboardKey.arrowLeft},
  ShortcutKey.up: {PhysicalKeyboardKey.arrowUp},
  ShortcutKey.down: {PhysicalKeyboardKey.arrowDown},
  ShortcutKey.semiColon: {PhysicalKeyboardKey.semicolon},
  ShortcutKey.enter: {
    PhysicalKeyboardKey.enter,
    PhysicalKeyboardKey.numpadEnter
  },
  ShortcutKey.equal: {
    PhysicalKeyboardKey.equal,
    PhysicalKeyboardKey.numpadEqual
  },
  ShortcutKey.minus: {
    PhysicalKeyboardKey.minus,
    PhysicalKeyboardKey.numpadSubtract
  },
};

Map<ShortcutKey, String> _keyNames = {
  ShortcutKey.alt: 'alt',
  ShortcutKey.enter: 'enter',
  ShortcutKey.shift: 'shift',
  ShortcutKey.meta: 'meta',
  ShortcutKey.ctrl: 'ctrl',
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
  ShortcutKey.semiColon: ';',
};

String keyname(ShortcutKey key) {
  var name = _keyNames[key];
  if (name != null) {
    return name;
  }
  switch (key) {
    case ShortcutKey.systemCmd:
      return Platform.instance.isMac ? 'cmd' : 'ctrl';
      break;
    default:
      return null;
  }
}

ShortcutKey keyForCode(int code) {
  switch (code) {
    case 0x12:
      return ShortcutKey.alt;
    case 0x0D:
      return ShortcutKey.enter;
    case 0x10:
      return ShortcutKey.shift;
    case 0x5B:
      return Platform.instance.isMac ? ShortcutKey.systemCmd : ShortcutKey.meta;
    case 0x11:
      return Platform.instance.isMac ? ShortcutKey.ctrl : ShortcutKey.systemCmd;
    case 0xBC:
      return ShortcutKey.comma;
    case 0xBE:
      return ShortcutKey.period;
    case 0x41:
      return ShortcutKey.a;
    case 0x42:
      return ShortcutKey.b;
    case 0x43:
      return ShortcutKey.c;
    case 0x44:
      return ShortcutKey.d;
    case 0x45:
      return ShortcutKey.e;
    case 0x46:
      return ShortcutKey.f;
    case 0x47:
      return ShortcutKey.g;
    case 0x48:
      return ShortcutKey.h;
    case 0x49:
      return ShortcutKey.i;
    case 0x4A:
      return ShortcutKey.j;
    case 0x4B:
      return ShortcutKey.k;
    case 0x4C:
      return ShortcutKey.l;
    case 0x4D:
      return ShortcutKey.m;
    case 0x4E:
      return ShortcutKey.n;
    case 0x4F:
      return ShortcutKey.o;
    case 0x50:
      return ShortcutKey.p;
    case 0x51:
      return ShortcutKey.q;
    case 0x52:
      return ShortcutKey.r;
    case 0x53:
      return ShortcutKey.s;
    case 0x54:
      return ShortcutKey.t;
    case 0x55:
      return ShortcutKey.u;
    case 0x56:
      return ShortcutKey.v;
    case 0x57:
      return ShortcutKey.w;
    case 0x58:
      return ShortcutKey.x;
    case 0x59:
      return ShortcutKey.y;
    case 0x5A:
      return ShortcutKey.z;
    case 0x30:
      return ShortcutKey.zero;
    case 0x31:
      return ShortcutKey.one;
    case 0x32:
      return ShortcutKey.two;
    case 0x33:
      return ShortcutKey.three;
    case 0x34:
      return ShortcutKey.four;
    case 0x35:
      return ShortcutKey.five;
    case 0x36:
      return ShortcutKey.six;
    case 0x37:
      return ShortcutKey.seven;
    case 0x38:
      return ShortcutKey.eight;
    case 0x39:
      return ShortcutKey.nine;
    case 0xC0:
      return ShortcutKey.backquote;
    case 0x08:
      return ShortcutKey.backspace;
    case 0x2E:
      return ShortcutKey.delete;
    case 0x1B:
      return ShortcutKey.esc;
    case 0x20:
      return ShortcutKey.space;
    case 0x24:
      return ShortcutKey.home;
    case 0x23:
      return ShortcutKey.end;
    case 0xDB:
      return ShortcutKey.bracketLeft;
    case 0xDD:
      return ShortcutKey.bracketRight;
    case 0xBF:
      return ShortcutKey.slash;
    case 0xDC:
      return ShortcutKey.backslash;
    case 0x27:
      return ShortcutKey.right;
    case 0x25:
      return ShortcutKey.left;
    case 0x26:
      return ShortcutKey.up;
    case 0x28:
      return ShortcutKey.down;
    case 0xBA:
      return ShortcutKey.semiColon;
    case 0xBB:
      return ShortcutKey.equal;
    case 0xBD:
      return ShortcutKey.minus;
  }
  return null;
}

enum ShortcutKey {
  alt,
  enter,
  shift,
  meta,
  ctrl,
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
  slash,
  backslash,
  right,
  left,
  up,
  down,
  semiColon,
  equal,
  minus,
}
