import SwiftUI

@main
struct WatchUnlockiPhoneApp: App {
    @WKExtensionDelegateAdaptor(ExtensionDelegate.self) var extensionDelegate

    var body: some Scene {
        WindowGroup {
            ContentView(motionService: MotionDataService())
        }
    }
}

