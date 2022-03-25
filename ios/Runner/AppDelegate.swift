import UIKit
import Flutter

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
    let chars = documentsPath.cString(using: String.Encoding.utf8)
    set_root(chars)
      
      FlutterMethodChannel.init(name: "cross", binaryMessenger: controller as! FlutterBinaryMessenger).setMethodCallHandler { (call, result) in
          Thread {
              switch (call.method){
              case "saveImageFileToGallery":
                  if let path = call.arguments as? String{
                      do {
                          let fileURL: URL = URL(fileURLWithPath: path)
                          let imageData = try Data(contentsOf: fileURL)
                          if let uiImage = UIImage(data: imageData) {
                              UIImageWriteToSavedPhotosAlbum(uiImage, nil, nil, nil)
                              result("OK")
                          }else{
                              result(FlutterError(code: "", message: "Error loading image ", details: ""))
                          }
                      } catch {
                          result(FlutterError(code: "", message: "Error loading image : \(error)", details: ""))
                      }
                  }else{
                      result(FlutterError(code: "", message: "params error", details: ""))
                  }
              default:
                  result(FlutterMethodNotImplemented)
              }
          }.start()
      }
      
    print("dummy_value=\(dummy_method_to_enforce_bundling())");
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
