import Cocoa
import FlutterMacOS

@NSApplicationMain
class AppDelegate: FlutterAppDelegate {
  override init() {
    super.init()
    let folder = NSHomeDirectory()+"/Library/Application Support/pansy"
    let chars = folder.cString(using: String.Encoding.utf8)
    set_root(chars!)
  }
  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    dummy_method_to_enforce_bundling()
    return true
  }
}
