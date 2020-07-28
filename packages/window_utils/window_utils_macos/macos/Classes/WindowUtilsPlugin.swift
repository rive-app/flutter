import Cocoa
import Foundation
import FlutterMacOS
import WebKit

// Handler class for handling keypresses
class KeyPressHandler : NSObject, FlutterStreamHandler {
    private var _eventSink: FlutterEventSink?

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        _eventSink = events
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        _eventSink = nil
        return nil;
    }

    func keyPress(_ keyCode: UInt32) {
        _eventSink?(keyCode)
    }
}

// Global handler for routing key presses
var keyPressHandler:KeyPressHandler? = nil

public class WindowUtilsPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "plugins.rive.app/window_utils", binaryMessenger: registrar.messenger)
        let instance = WindowUtilsPlugin(channel: channel)
        registrar.addMethodCallDelegate(instance, channel: channel)

        let keypressChannel = FlutterEventChannel(name: "plugins.rive.app/key_press", binaryMessenger: registrar.messenger)
        keyPressHandler = KeyPressHandler()
        keypressChannel.setStreamHandler(keyPressHandler)
        
        NSLog("Registering windows plugin")
    }
    
    var mouseStackCount = 1;
    
    var _channel: FlutterMethodChannel;
    init(channel flutterChannel:FlutterMethodChannel) {
        _channel = flutterChannel;
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getWindowOffset":
            let window = NSApplication.shared.keyWindow
            let origin = window?.frame.origin
            var _output: [String: Any?] = [:]
            _output["offsetX"] = Double(origin?.x ?? 0)
            _output["offsetY"] = Double(origin?.y ?? 0)
            result(_output)
        case "getWindowSize":
            let window = NSApplication.shared.keyWindow
            let size = window?.frame.size
            var _output: [String: Any?] = [:]
            _output["width"] = Double(size?.width ?? 0)
            _output["height"] = Double(size?.height ?? 0)
            result(_output)
        case "getScreenSize":
            let window = NSApplication.shared.keyWindow
            let size = window?.screen?.frame.size
            var _output: [String: Any?] = [:]
            _output["width"] = Double(size?.width ?? 0)
            _output["height"] = Double(size?.height ?? 0)
            result(_output)
        case "hideTitleBar":
            if let window = NSApplication.shared.mainWindow
            {
                window.titleVisibility = .hidden
                window.styleMask.insert(.fullSizeContentView)
                window.titlebarAppearsTransparent = true
                window.contentView?.wantsLayer = true
                window.isMovableByWindowBackground = true
                window.isMovable = false
                result(true)
            } else {
                result(false)
            }
        case "showTitleBar":
            let window = NSApplication.shared.keyWindow
            window?.styleMask.update(with: .titled)
            result(true)
        case "windowTitleDoubleTap":
            let window = NSApplication.shared.keyWindow
            let isZoomed = window?.isZoomed ?? false
            window?.setIsZoomed(!isZoomed)
            result(true)
        case "closeWindow":
            let window = NSApplication.shared.keyWindow
            window?.close()
            result(true)
        case "centerWindow":
            let window = NSApplication.shared.keyWindow
            window?.center()
            result(true)
        case "setPosition":
            let args = call.arguments as? [String: Any]
            let x: Double = (args?["x"] as? Double)!
            let y: Double = (args?["y"] as? Double)!
            let point: NSPoint = NSPoint(x: x, y: y)
            let window = NSApplication.shared.keyWindow
            window?.setFrameOrigin(point)
            result(true)
        case "setSize":
            let args = call.arguments as? [String: Any]
            let width: Double = (args?["width"] as? Double)!
            let height: Double = (args?["height"] as? Double)!
            resizeWindowWithDelay(width: width, height: height, retries: 0)
            result(true)
        case "startDrag":
            let window = NSApplication.shared.keyWindow
            if let event: NSEvent = window?.currentEvent
            {
                window?.performDrag(with: event)
            }
            result(true)
        case "childWindowsCount":
            let window = NSApplication.shared.keyWindow
            let count = window?.childWindows?.count ?? 0
            result(count)
        case "mouseStackCount":
            let count = mouseStackCount
            result(count)
        case "resetCursor":
            mouseStackCount = 1
            NSCursor.arrow.set()
            result(true)
        case "removeCursorFromStack":
            if (mouseStackCount == 1) {
                NSCursor.arrow.set()
            } else {
                NSCursor.current.pop()
                mouseStackCount -= 1
            }
            result(true)
        case "hideCursor":
            for _ in 1...mouseStackCount {
                NSCursor.hide()
            }
            result(true)
        case "showCursor":
            for _ in 1...mouseStackCount {
                NSCursor.unhide()
            }
            result(true)
        case "setCursor":
            let args = call.arguments as? [String: Any]
            let update: Bool = (args?["update"] as? Bool)!
            let type: String = (args?["type"] as? String)!
            var cursor: NSCursor
            switch type {
            case "arrow": cursor = NSCursor.arrow
            case "beamVertical": cursor = NSCursor.iBeam
            case "beamHorizontial": cursor = NSCursor.iBeamCursorForVerticalLayout
            case "crossHair": cursor = NSCursor.crosshair
            case "closedHand": cursor = NSCursor.closedHand
            case "openHand": cursor = NSCursor.openHand
            case "pointingHand": cursor = NSCursor.pointingHand
            case "resizeLeft": cursor = NSCursor.resizeLeft
            case "resizeRight": cursor = NSCursor.resizeRight
            case "resizeLeftRight": cursor = NSCursor.resizeLeftRight
            case "resizeUp": cursor = NSCursor.resizeUp
            case "resizeDown": cursor = NSCursor.resizeDown
            case "resizeUpDown": cursor = NSCursor.resizeUpDown
            case "disappearingItem": cursor = NSCursor.disappearingItem
            case "notAllowed": cursor = NSCursor.operationNotAllowed
            case "dragLink": cursor = NSCursor.dragLink
            case "dragCopy": cursor = NSCursor.dragCopy
            case "contextMenu": cursor = NSCursor.contextualMenu
            default:
                cursor = NSCursor.arrow
            }
            if (update) {
                cursor.push()
                mouseStackCount += 1
            } else {
                cursor.set()
            }
            result(true)
        case "openWebView":
            let args = call.arguments as? [String: Any]
            let width: Int? = args?["width"] as? Int
            let height: Int? = args?["height"] as? Int
            let x: Double? = args?["x"] as? Double
            let y: Double? = args?["y"] as? Double
            let key: String = args?["key"] as! String
            let url: String = args?["url"] as! String
            let jsHandler: String = args?["jsMessage"] as! String
            createWebWindow(
                key: key,
                url: url,
                jsMessage: jsHandler,
                x: x,
                y: y,
                width: width,
                height: height,
                result: result
            )
            break
        case "closeWebView":
            let args = call.arguments as? [String: Any]
            let key: String! = args?["key"] as? String
            result(closeWindow(_key: key))
            break
        case "windowCount":
            result(NSApp.windows.count)
            break
        case "keyIndex":
            let args = call.arguments as? [String: Any]
            let _key: String? = args?["key"] as? String
            let index = NSApp.windows.firstIndex(where: { $0.title == _key })
            result(index ?? 0)
            break
        case "getWindowStats":
            let args = call.arguments as? [String: Any]
            let _key: String? = args?["key"] as? String
            let window = _key != nil ? NSApp.windows.first(where: { $0.title == _key }) : NSApplication.shared.keyWindow
            let screen = window?.frame
            let origin = screen?.origin
            let size = screen?.size
            var _args: [String: Any?] = [:]
            _args["offsetX"] = Double(origin!.x)
            _args["offsetY"] = Double(origin!.y)
            _args["width"] = Double(size!.width)
            _args["height"] = Double(size!.height)
            result(_args)
        case "moveWindow":
            let args = call.arguments as? [String: Any]
            let _key: String? = args?["key"] as? String
            let x: Double = args?["x"] as! Double
            let y: Double = args?["y"] as! Double
            let window = NSApp.windows.first(where: { $0.title == _key })
            window?.setFrameOrigin(NSPoint(x: x, y: y))
            result(true)
        case "resizeWindow":
            let args = call.arguments as? [String: Any]
            let _key: String? = args?["key"] as? String
            let width: Double = args?["width"] as! Double
            let height: Double = args?["height"] as! Double
            let window = NSApp.windows.first(where: { $0.title == _key })
            window?.setContentSize(NSSize(width: width, height: height))
            result(true)
        case "initInputHelper":
            initInputHelperWithDelay(channel: _channel, retries: 0)
            result(true)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    func createWebWindow(key: String, url: String, jsMessage: String, x: Double? = nil, y: Double? = nil, width: Int? = nil, height: Int? = nil, result: @escaping FlutterResult) {
        let _webView = WebView()
        _webView.url = url
        _webView.jsHandler = jsMessage
        // Only message once, when we get our handler data or when the window is closed.
        var messaged = false;
        _webView.closed = { (message: Any) -> Void in
            if(!messaged) {
                messaged = true
                result(message)
            }
        }
        if (jsMessage != "") {
            _webView.jsResponse = { (message: Any) -> Void in
                if(!messaged) {
                    messaged = true
                    result(message)
                }
            }
        }
        
        let window = NSWindow()
        window.styleMask = NSWindow.StyleMask(rawValue: 0xf)
        window.backingType = .buffered
        window.title = key;
        
        window.contentViewController = _webView
        if let screen = window.screen {
            let screenRect = screen.visibleFrame
            let newWidth = width ?? Int(screenRect.maxX / 2)
            let newHeight = height ?? Int(screenRect.maxY / 2)
            var newOriginX: CGFloat = (screenRect.maxX / 2) - CGFloat(Double(newWidth) / 2)
            var newOriginY: CGFloat = (screenRect.maxY / 2) - CGFloat(Double(newHeight) / 2)
            if (x != nil) { newOriginX = CGFloat(x!) }
            if (y != nil) { newOriginY = CGFloat(y!) }
            window.setFrameOrigin(NSPoint(x: newOriginX, y: newOriginY))
            window.setContentSize(NSSize(width: newWidth, height: newHeight))
        }
        let windowController = NSWindowController()
        windowController.contentViewController = window.contentViewController
        windowController.shouldCascadeWindows = true
        windowController.window = window
        windowController.showWindow(self)
    }
    
    func closeWindow(_key: String) -> Bool {
        let window = NSApp.windows.first(where: { $0.title == _key })
        window?.close()
        return true
    }
}

func resizeWindowWithDelay(width: Double, height: Double, retries: UInt8) {
    let maxRetries = 10
    if (retries < maxRetries) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if let window = NSApplication.shared.mainWindow
            {
                window.setContentSize(NSSize(width: width, height: height))
            } else {
                resizeWindowWithDelay(width: width, height: height, retries: retries + 1)
            }
        }
    }
}


func initInputHelperWithDelay(channel: FlutterMethodChannel, retries: UInt8) {
    let maxRetries = 10
    if (retries < maxRetries) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if let window = NSApplication.shared.mainWindow
            {
                let screen = window.frame
                let size = screen.size
                
                let frame:CGRect = CGRect(origin: .zero, size: size)
                let view:InputHelperView = InputHelperView(frame: frame, channel: channel)
                
                for subview in window.contentView!.subviews {
                    if subview is InputHelperView {
                        (subview as! InputHelperView).removeMonitors()
                        subview.removeFromSuperview()
                    }
                }
                window.contentView?.addSubview(view)
            } else {
                initInputHelperWithDelay(channel: channel, retries: retries + 1)
            }
        }
    }
}

class InputHelperView: NSView {
    let fileTypes = ["jpg", "jpeg", "bmp", "png", "gif", "riv", "svg", "flr2d"]
    
    let NSFilenamesPboardType = NSPasteboard.PasteboardType("NSFilenamesPboardType")
    var channel:FlutterMethodChannel?

    var isMetaDown:Bool = false
    var isControlDown:Bool = false
    var isCapsLockDown:Bool = false
    var isShiftDown:Bool = false
    var isOptionDown:Bool = false
    
    var monitorKeyDown: Any?
    var monitorKeyUp: Any?
    var monitorKeyFlags: Any?
    
    init(frame frameRect: NSRect, channel flutterChannel:FlutterMethodChannel) {
        channel = flutterChannel
        super.init(frame: frameRect)
        self.autoresizingMask = [.width, .height]
        registerForDraggedTypes([NSFilenamesPboardType])
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(appFocused),
                                               name: NSWindow.didBecomeKeyNotification,
                                               object: nil)

        monitorKeyDown = NSEvent.addLocalMonitorForEvents(matching: .keyDown, handler: keyDownHandler)
        monitorKeyUp = NSEvent.addLocalMonitorForEvents(matching: .keyUp, handler: keyUpHandler)
        monitorKeyFlags = NSEvent.addLocalMonitorForEvents(matching: .flagsChanged, handler: flagsChangedHandler)
    }
    
    func removeMonitors() {
        NotificationCenter.default.removeObserver(self,
        name: NSWindow.didBecomeKeyNotification,
        object: nil)

        NSEvent.removeMonitor(monitorKeyDown!)
        NSEvent.removeMonitor(monitorKeyUp!)
        NSEvent.removeMonitor(monitorKeyFlags!)
    }

    @objc func appFocused() {
        syncFlags(NSEvent.modifierFlags.rawValue)
    }

    func keyDownHandler(with event: NSEvent) -> NSEvent? {
        // NSLog("down \(event.keyCode) \(event.characters) \(event.isARepeat)")
        // First check the logical key mapping. If there's no mapping, fall back to the physical key mapping
        if let logicalCharacters = event.characters {
            // If it's not empty, grab the first key
            if let char = logicalCharacters.first {
                // NSLog("Logical key \(char) pressed")
                // Calculate the unicode value
                let unicode:UInt32 = char.unicodeScalars.map { $0.value }.reduce(0, +)
                // NSLog(String(format: "Unicode value 0x%X", unicode))
                // If it maps, report the mapped keycode
                if let mappedLogicalKeyCode = MacLogicalToWeb[unicode] {
                    reportKey(mappedLogicalKeyCode, true, event.isARepeat)
                    return event
                }
            }
        }
        // No logical key mapping found, return the physical mapped keycode
        reportMacKey(event.keyCode, true, event.isARepeat)
        return event
    }

    func reportKey(_ code:UInt32, _ isPressed:Bool, _ isRepeat:Bool) {
        var fullKeyCode:UInt32 = code
        if(!isPressed) {
            fullKeyCode |= (1<<18)
        } 
        if(isRepeat) {
            fullKeyCode |= (1<<17)
        }
        keyPressHandler!.keyPress(fullKeyCode)
    }

    func reportMacKey(_ macKeyCode:UInt16, _ isPressed:Bool, _ isRepeat:Bool) {
        if(macKeyCode < MacToWeb.count) {
            reportKey(MacToWeb[Int(macKeyCode)], isPressed, isRepeat)
        }
        else {
            print("Unhandled keycode \(macKeyCode)")
        }
    }

    func keyUpHandler(with event: NSEvent) -> NSEvent? {
        // print("up \(event.keyCode)")
        reportMacKey(event.keyCode, false, false)
        return event
    }

    func syncFlags(_ rawValue:UInt) {
        let meta = (rawValue & NSEvent.ModifierFlags.command.rawValue) != 0
        if(meta != isMetaDown) {
            isMetaDown = meta
            // print("Meta changed \(meta)")
            reportKey(KeyCode.lwin.rawValue, isMetaDown, false)
            // report meta down...
        }
        let ctrl = (rawValue & NSEvent.ModifierFlags.control.rawValue) != 0
        if(ctrl != isControlDown) {
            isControlDown = ctrl
            // print("ctrl changed \(ctrl)")
            reportKey(KeyCode.control.rawValue, isControlDown, false)
            // report control down...
        }
        let caps = (rawValue & NSEvent.ModifierFlags.capsLock.rawValue) != 0
        if(caps != isCapsLockDown) {
            isCapsLockDown = caps
            // report caps down...
            // print("caps changed \(caps)")
            reportKey(KeyCode.capital.rawValue, isCapsLockDown, false)
        }
        let shift = (rawValue & NSEvent.ModifierFlags.shift.rawValue) != 0
        if(shift != isShiftDown) {
            isShiftDown = shift
            // report shift down...
            // print("shift changed \(shift)")
            reportKey(KeyCode.shift.rawValue, isShiftDown, false)
        }
        let option = (rawValue & NSEvent.ModifierFlags.option.rawValue) != 0
        if(option != isOptionDown) {
            isOptionDown = option
            // print("option changed \(option)")
            // report shift down...
            reportKey(KeyCode.menu.rawValue, isOptionDown, false)
        }
    }
    
    func flagsChangedHandler(with event: NSEvent) -> NSEvent? {
        syncFlags(event.modifierFlags.rawValue)
        return event
    }
    
    required init?(coder: NSCoder) {
        channel = nil
        super.init(coder: coder)
    }
    
    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        if checkExtension(drag: sender) == true {
            return .copy
        } else {
            return NSDragOperation()
        }
    }
    
    func checkExtension(drag: NSDraggingInfo) -> Bool {
        if let board = drag.draggingPasteboard.propertyList(forType: NSFilenamesPboardType) as? NSArray, let path = board[0] as? String {
            let url = NSURL.fileURL(withPath: path)
            let fileExtension = url.pathExtension.lowercased()
            return fileTypes.contains(fileExtension)
            
        }
        return false
    }
    
    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        guard let pasteboard = sender.draggingPasteboard.propertyList(forType: NSFilenamesPboardType) as? NSArray,
            let path = pasteboard[0] as? String
            else { return false }
        
        channel?.invokeMethod("filesDropped", arguments: [path])
        
        return true
    }
    
    override var acceptsFirstResponder : Bool {
        return false
    }
    
    override var canBecomeKeyView : Bool {
        return false
    }
}

class WebView: NSViewController, WKUIDelegate, WKScriptMessageHandler, WKNavigationDelegate, NSWindowDelegate {
    var webView: WKWebView!
    var url = "https://www.apple.com"
    var jsHandler: String = ""
    var jsResponse: (Any?) -> Void? = { (message: Any) -> Void in
        print(message)
    }
    var closed: (Any?) -> Void? = { (message: Any) -> Void in
        print(message)
    }
    
    
    // NSViewController
    override func loadView() {
        let webConfig = WKWebViewConfiguration()
        webView = WKWebView(frame: .zero, configuration: webConfig)
        // Register as WKUIDelegate
        webView.uiDelegate = self
        // Register as WKNavigationDelegate
        webView.navigationDelegate = self
        if (jsHandler != "") {
            // Register as WKScriptMessageHandler
            webView.configuration.userContentController.add(self, name: jsHandler)
        }
        view = webView
        
        // Clear cookies
        let dataStore = WKWebsiteDataStore.default()
        let allTypes = WKWebsiteDataStore.allWebsiteDataTypes()
        dataStore.fetchDataRecords(ofTypes: allTypes) { allRecords in
            allRecords.forEach { record in
                dataStore.removeData(ofTypes: record.dataTypes,
                                     for: [record], completionHandler: {})
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let request = URLRequest(url: URL(string: url)!)
        webView.load(request)
    }
    
    override func viewDidAppear() {
        guard let window = self.view.window else {
            print("No window?")
            return
        }
        // Add `self` as NSWindowDelegate to capture `windowWillClose` event.
        window.delegate = self
        // Completely remove titlebar.
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.styleMask.insert(.fullSizeContentView)
    }
    
    // WKScriptMessageHandler
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == jsHandler {
            let val = message.body
            jsResponse(val)
        }
    }
    
    // NSWindowDelegate
    func windowWillClose(_ notification: Notification) {
        closed(nil);
    }
    
    // WKNavigationDelegate
    func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
        // print("Redirecting?\n\(webView.url?.absoluteString ?? "Empty URL")")
    }
    
    deinit {
        webView = nil
    }
}


