import Cocoa
import Foundation
import FlutterMacOS
import WebKit

public class WindowUtils: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "window_utils", binaryMessenger: registrar.messenger)
        let instance = WindowUtils()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    var mouseStackCount = 1;
    
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
            let size: NSSize = NSSize(width: width, height: height)
            let window = NSApplication.shared.keyWindow
            window?.setContentSize(size)
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
                messaged = true;
                result(message)
            }
        }
        if (jsMessage != "") {
            _webView.jsResponse = { (message: Any) -> Void in
                if(!messaged) {
                    messaged = true;
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
