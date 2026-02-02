import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    // try? AVAudioSession.sharedInstance().setCategory(
    //   .ambient,
    //   mode: .default,
    //   options: [.mixWithOthers]
    // )
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}


