//
//  Generated file. Do not edit.
//

import FlutterMacOS
import Foundation

import cursor
import shared_preferences_macos
import url_launcher_macos
import window_utils

func RegisterGeneratedPlugins(registry: FlutterPluginRegistry) {
  CursorPlugin.register(with: registry.registrar(forPlugin: "CursorPlugin"))
  SharedPreferencesPlugin.register(with: registry.registrar(forPlugin: "SharedPreferencesPlugin"))
  UrlLauncherPlugin.register(with: registry.registrar(forPlugin: "UrlLauncherPlugin"))
  WindowUtils.register(with: registry.registrar(forPlugin: "WindowUtils"))
}
