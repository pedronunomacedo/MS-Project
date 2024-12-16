import UIKit
import WatchConnectivity
import BackgroundTasks

class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    private let backgroundTaskID = "Uni.FRI.UnlockiPhoneApplication.backgroundTask"

    // MARK: - Application Lifecycle
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        setupNotificationCenter()
        setupBackgroundTasks()

        // Ensure the session manager is initialized
        _ = iPhoneSessionManager.shared

        scheduleBackgroundTask()
        return true
    }

    // MARK: - Notifications
    private func setupNotificationCenter() {
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Error requesting notification authorization: \(error.localizedDescription)")
            } else {
                print("Notification permission granted: \(granted)")
            }
        }
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Display the notification as a banner, sound, or badge while in the foreground
        completionHandler([.banner, .sound, .badge])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        print("User interacted with notification: \(response.notification.request.identifier)")
        completionHandler()
    }

    // MARK: - Background Tasks
    private func setupBackgroundTasks() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: backgroundTaskID, using: nil) { [weak self] task in
            guard let task = task as? BGAppRefreshTask else { return }
            self?.handleBackgroundTask(task: task)
        }
    }

    private func scheduleBackgroundTask() {
        do {
            let taskRequest = BGAppRefreshTaskRequest(identifier: backgroundTaskID)
            try BGTaskScheduler.shared.submit(taskRequest)
        } catch {
            print("Failed to schedule background task: \(error.localizedDescription)")
        }
    }

    private func handleBackgroundTask(task: BGAppRefreshTask) {
        // Add your background task processing logic here
        task.setTaskCompleted(success: true)
    }    
}
