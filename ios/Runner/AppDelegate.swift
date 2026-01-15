import Flutter
import UIKit

private final class AlbumSaverStore {
  static let shared = AlbumSaverStore()
  private var savers: [ObjectIdentifier: AlbumSaver] = [:]

  func retain(_ saver: AlbumSaver) {
    savers[ObjectIdentifier(saver)] = saver
  }

  func release(_ saver: AlbumSaver) {
    savers.removeValue(forKey: ObjectIdentifier(saver))
  }
}

private final class AlbumSaver: NSObject {
  private let result: FlutterResult
  init(_ result: @escaping FlutterResult) {
    self.result = result
  }

  @objc func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
    AlbumSaverStore.shared.release(self)
    if let error = error {
      result(FlutterError(code: "save_failed", message: error.localizedDescription, details: nil))
      return
    }
    result(true)
  }
}

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

      let controller = self.window.rootViewController as! FlutterViewController
      let channel = FlutterMethodChannel.init(name: "cross", binaryMessenger: controller as! FlutterBinaryMessenger)

      channel.setMethodCallHandler { (call, result) in
          Thread {
              if call.method == "root" {
                  let documentsPath = NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, .userDomainMask, true)[0]
                  result(documentsPath)
              } else if call.method == "saveImageToGallery" {
                  guard let args = call.arguments as? [String: Any],
                        let path = args["path"] as? String
                  else {
                      result(false)
                      return
                  }

                  guard let image = UIImage(contentsOfFile: path) else {
                      result(false)
                      return
                  }

                  DispatchQueue.main.async {
                      let saver = AlbumSaver(result)
                      AlbumSaverStore.shared.retain(saver)
                      UIImageWriteToSavedPhotosAlbum(
                        image,
                        saver,
                        #selector(AlbumSaver.image(_:didFinishSavingWithError:contextInfo:)),
                        nil
                      )
                  }
              } else {
                  result(FlutterMethodNotImplemented)
              }
          }.start()
      }

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
