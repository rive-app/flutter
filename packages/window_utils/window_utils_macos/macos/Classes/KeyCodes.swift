enum KeyCode: UInt32 {
    case back = 0x08 
    case tab = 0x09
    case backTab = 0x0A
    case clear = 0x0C
    case enter = 0x0D
    case shift = 0x10
    case control = 0x11
    case menu = 0x12
    case pause = 0x13
    case capital = 0x14
    case kana = 0x15
    case junja = 0x17
    case final = 0x18
    case kanji = 0x19
    case escape = 0x1B
    case convert = 0x1C
    case nonconvert = 0x1D
    case accept = 0x1E
    case modechange = 0x1F
    case space = 0x20
    case prior = 0x21
    case next = 0x22
    case end = 0x23
    case home = 0x24
    case left = 0x25
    case up = 0x26
    case right = 0x27
    case down = 0x28
    case select = 0x29
    case print = 0x2A
    case execute = 0x2B
    case snapshot = 0x2C
    case insert = 0x2D
    case delete = 0x2E
    case help = 0x2F
    case n0 = 0x30
    case n1 = 0x31
    case n2 = 0x32
    case n3 = 0x33
    case n4 = 0x34
    case n5 = 0x35
    case n6 = 0x36
    case n7 = 0x37
    case n8 = 0x38
    case n9 = 0x39
    case a = 0x41
    case b = 0x42
    case c = 0x43
    case d = 0x44
    case e = 0x45
    case f = 0x46
    case g = 0x47
    case h = 0x48
    case i = 0x49
    case j = 0x4A
    case k = 0x4B
    case l = 0x4C
    case m = 0x4D
    case n = 0x4E
    case o = 0x4F
    case p = 0x50
    case q = 0x51
    case r = 0x52
    case s = 0x53
    case t = 0x54
    case u = 0x55
    case v = 0x56
    case w = 0x57
    case x = 0x58
    case y = 0x59
    case z = 0x5A
    case lwin = 0x5B
    case rwin = 0x5C
    case apps = 0x5D
    case sleep = 0x5F
    case numpad0 = 0x60
    case numpad1 = 0x61
    case numpad2 = 0x62
    case numpad3 = 0x63
    case numpad4 = 0x64
    case numpad5 = 0x65
    case numpad6 = 0x66
    case numpad7 = 0x67
    case numpad8 = 0x68
    case numpad9 = 0x69
    case multiply = 0x6A
    case add = 0x6B
    case separator = 0x6C
    case subtract = 0x6D
    case decimal = 0x6E
    case divide = 0x6F
    case f1 = 0x70
    case f2 = 0x71
    case f3 = 0x72
    case f4 = 0x73
    case f5 = 0x74
    case f6 = 0x75
    case f7 = 0x76
    case f8 = 0x77
    case f9 = 0x78
    case f10 = 0x79
    case f11 = 0x7A
    case f12 = 0x7B
    case f13 = 0x7C
    case f14 = 0x7D
    case f15 = 0x7E
    case f16 = 0x7F
    case f17 = 0x80
    case f18 = 0x81
    case f19 = 0x82
    case f20 = 0x83
    case f21 = 0x84
    case f22 = 0x85
    case f23 = 0x86
    case f24 = 0x87
    case numlock = 0x90
    case scroll = 0x91
    case lshift = 0xA0
    case rshift = 0xA1
    case lcontrol = 0xA2
    case rcontrol = 0xA3
    case lmenu = 0xA4
    case rmenu = 0xA5
    case browserBack = 0xA6
    case browserForward = 0xA7
    case browserRefresh = 0xA8
    case browserStop = 0xA9
    case browserSearch = 0xAA
    case browserFavorites = 0xAB
    case browserHome = 0xAC
    case volumeMute = 0xAD
    case volumeDown = 0xAE
    case volumeUp = 0xAF
    case mediaNextTrack = 0xB0
    case mediaPrevTrack = 0xB1
    case mediaStop = 0xB2
    case mediaPlayPause = 0xB3
    case mediaLaunchMail = 0xB4
    case mediaLaunchMediaSelect = 0xB5
    case mediaLaunchApp1 = 0xB6
    case mediaLaunchApp2 = 0xB7
    case oem1 = 0xBA
    case oemPlus = 0xBB
    case oemComma = 0xBC
    case oemMinus = 0xBD
    case oemPeriod = 0xBE
    case oem2 = 0xBF
    case oem3 = 0xC0
    case oem4 = 0xDB
    case oem5 = 0xDC
    case oem6 = 0xDD
    case oem7 = 0xDE
    case oem8 = 0xDF
    case oem102 = 0xE2
    case processkey = 0xE5
    case packet = 0xE7
    case attn = 0xF6
    case crsel = 0xF7
    case exsel = 0xF8
    case ereof = 0xF9
    case play = 0xFA
    case zoom = 0xFB
    case noname = 0xFC
    case pa1 = 0xFD
    case oemClear = 0xFE
    case unknown = 0xE0
}

let MacToWeb:[UInt32] = [
    KeyCode.a.rawValue,
      KeyCode.s.rawValue,
      KeyCode.d.rawValue,
      KeyCode.f.rawValue,
      KeyCode.h.rawValue,
      KeyCode.g.rawValue,
      KeyCode.z.rawValue,
      KeyCode.x.rawValue,
      KeyCode.c.rawValue,
      KeyCode.v.rawValue,
      KeyCode.oem3.rawValue,
      KeyCode.b.rawValue,
      KeyCode.q.rawValue,
      KeyCode.w.rawValue,
      KeyCode.e.rawValue,
      KeyCode.r.rawValue,
      KeyCode.y.rawValue,
      KeyCode.t.rawValue,
      KeyCode.n1.rawValue,
      KeyCode.n2.rawValue,
      KeyCode.n3.rawValue,
      KeyCode.n4.rawValue,
      KeyCode.n6.rawValue,
      KeyCode.n5.rawValue,
      KeyCode.oemPlus.rawValue,
      KeyCode.n9.rawValue,
      KeyCode.n7.rawValue,
      KeyCode.oemMinus.rawValue,
      KeyCode.n8.rawValue,
      KeyCode.n0.rawValue,
      KeyCode.oem6.rawValue,
      KeyCode.o.rawValue,
      KeyCode.u.rawValue,
      KeyCode.oem4.rawValue,
      KeyCode.i.rawValue,
      KeyCode.p.rawValue,
      KeyCode.enter.rawValue,
      KeyCode.l.rawValue,
      KeyCode.j.rawValue,
      KeyCode.oem7.rawValue,
      KeyCode.k.rawValue,
      KeyCode.oem1.rawValue,
      KeyCode.oem5.rawValue,
      KeyCode.oemComma.rawValue,
      KeyCode.oem2.rawValue,
      KeyCode.n.rawValue,
      KeyCode.m.rawValue,
      KeyCode.oemPeriod.rawValue,
      KeyCode.tab.rawValue,
      KeyCode.space.rawValue,
      KeyCode.oem3.rawValue,
      KeyCode.back.rawValue,
      KeyCode.unknown.rawValue,
      KeyCode.escape.rawValue,
      KeyCode.apps.rawValue,
      KeyCode.lwin.rawValue,
      KeyCode.shift.rawValue,
      KeyCode.capital.rawValue,
      KeyCode.menu.rawValue,
      KeyCode.control.rawValue,
      KeyCode.shift.rawValue,
      KeyCode.menu.rawValue,
      KeyCode.control.rawValue,
      KeyCode.unknown.rawValue,
      KeyCode.f17.rawValue,
      KeyCode.decimal.rawValue,
      KeyCode.unknown.rawValue,
      KeyCode.multiply.rawValue,
      KeyCode.unknown.rawValue,
      KeyCode.add.rawValue,
      KeyCode.unknown.rawValue,
      KeyCode.clear.rawValue,
      KeyCode.volumeUp.rawValue,
      KeyCode.volumeDown.rawValue,
      KeyCode.volumeMute.rawValue,
      KeyCode.divide.rawValue,
      KeyCode.enter.rawValue,
      KeyCode.unknown.rawValue,
      KeyCode.subtract.rawValue,
      KeyCode.f18.rawValue,
      KeyCode.f19.rawValue,
      KeyCode.oemPlus.rawValue,
      KeyCode.numpad0.rawValue,
      KeyCode.numpad1.rawValue,
      KeyCode.numpad2.rawValue,
      KeyCode.numpad3.rawValue,
      KeyCode.numpad4.rawValue,
      KeyCode.numpad5.rawValue,
      KeyCode.numpad6.rawValue,
      KeyCode.numpad7.rawValue,
      KeyCode.f20.rawValue,
      KeyCode.numpad8.rawValue,
      KeyCode.numpad9.rawValue,
      KeyCode.unknown.rawValue,
      KeyCode.unknown.rawValue,
      KeyCode.unknown.rawValue,
      KeyCode.f5.rawValue,
      KeyCode.f6.rawValue,
      KeyCode.f7.rawValue,
      KeyCode.f3.rawValue,
      KeyCode.f8.rawValue,
      KeyCode.f9.rawValue,
      KeyCode.unknown.rawValue,
      KeyCode.f11.rawValue,
      KeyCode.unknown.rawValue,
      KeyCode.f13.rawValue,
      KeyCode.f16.rawValue,
      KeyCode.f14.rawValue,
      KeyCode.unknown.rawValue,
      KeyCode.f10.rawValue,
      KeyCode.apps.rawValue,
      KeyCode.f12.rawValue,
      KeyCode.unknown.rawValue,
      KeyCode.f15.rawValue,
      KeyCode.insert.rawValue,
      KeyCode.home.rawValue,
      KeyCode.prior.rawValue,
      KeyCode.delete.rawValue,
      KeyCode.f4.rawValue,
      KeyCode.end.rawValue,
      KeyCode.f2.rawValue,
      KeyCode.next.rawValue,
      KeyCode.f1.rawValue,
      KeyCode.left.rawValue,
      KeyCode.right.rawValue,
      KeyCode.down.rawValue,
      KeyCode.up.rawValue,
      KeyCode.unknown.rawValue,
]
