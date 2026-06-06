import UIKit
import Flutter
import GoogleMaps // <-- ADICIONE ESTA LINHA

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GMSServices.provideAPIKey("AIzaSyB7E4N1RhYJ4oh_n6FhlZ2Dbn-ua7IWH5k") // <-- ADICIONE ESTA LINHA
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}