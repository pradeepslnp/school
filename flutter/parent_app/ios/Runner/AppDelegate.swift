import Flutter
import GoogleMaps
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // P-04 Live Trip Map. Key comes from Info.plist's GuardianMapsAPIKey, itself sourced from
    // an xcconfig build setting that is never committed (Info.plist, Secrets.xcconfig.example).
    // Skipped when unset: the SDK still initialises, it just renders no tiles.
    if let mapsApiKey = Bundle.main.object(forInfoDictionaryKey: "GuardianMapsAPIKey") as? String,
      !mapsApiKey.isEmpty
    {
      GMSServices.provideAPIKey(mapsApiKey)
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
