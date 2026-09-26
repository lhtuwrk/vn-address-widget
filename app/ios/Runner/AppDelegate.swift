import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // ADR 0002 §4 step 2/3: this is where the per-launch dataset-bootstrap
    // check and App Group path resolution (passed to Dart over a method
    // channel) will be wired up in phase1/01+. Phase0/03 scope: none of that
    // logic exists yet — this only proves the Flutter host boots.
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
