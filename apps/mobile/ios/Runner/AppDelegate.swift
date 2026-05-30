import GoogleMaps
import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private let googleMapsChannelName = "project_ynot/google_maps"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(
        name: googleMapsChannelName,
        binaryMessenger: controller.binaryMessenger
      )

      channel.setMethodCallHandler { call, result in
        switch call.method {
        case "configure":
          if
            let arguments = call.arguments as? [String: Any],
            let apiKey = arguments["apiKey"] as? String,
            !apiKey.isEmpty
          {
            GMSServices.provideAPIKey(apiKey)
          }
          result(nil)
        default:
          result(FlutterMethodNotImplemented)
        }
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
