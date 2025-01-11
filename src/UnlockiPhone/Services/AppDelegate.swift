import UIKit
import BackgroundTasks

class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    private let backgroundTaskID = "Uni.FRI.UnlockiPhoneApplication.backgroundTask"

    // MARK: - Application Lifecycle
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        setupNotificationCenter()
        setupBackgroundTasks()

        // Ensure iPhoneSessionManager is initialized
        _ = iPhoneSessionManager.shared
        return true
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        print("App became active.")
        iPhoneSessionManager.shared.handleAppActivation()
    }

    func applicationWillResignActive(_ application: UIApplication) {
        print("App will resign active.")
        iPhoneSessionManager.shared.handleAppDeactivation()
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        print("App entered background.")
        scheduleBackgroundTask()
    }

    func applicationWillTerminate(_ application: UIApplication) {
        print("App is terminating.")
        iPhoneSessionManager.shared.handleAppTermination()
    }

    // MARK: - Notifications
    private func setupNotificationCenter() {
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Notification authorization failed: \(error.localizedDescription)")
            } else {
                print("Notification permission granted: \(granted)")
            }
        }
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .badge])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        print("User interacted with notification: \(response.notification.request.identifier)")
        completionHandler()
    }

    // MARK: - Background Tasks
    private func setupBackgroundTasks() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: backgroundTaskID, using: nil) { task in
            guard let task = task as? BGAppRefreshTask else { return }
            self.handleBackgroundTask(task: task)
        }
    }

    private func scheduleBackgroundTask() {
        do {
            let taskRequest = BGAppRefreshTaskRequest(identifier: backgroundTaskID)
            taskRequest.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60)
            try BGTaskScheduler.shared.submit(taskRequest)
            print("Scheduled background task.")
        } catch {
            print("Failed to schedule background task: \(error.localizedDescription)")
        }
    }

    private func handleBackgroundTask(task: BGAppRefreshTask) {
        print("Handling background task.")
        iPhoneSessionManager.shared.handleBackgroundTask()
        task.setTaskCompleted(success: true)
        scheduleBackgroundTask()
    }
}
