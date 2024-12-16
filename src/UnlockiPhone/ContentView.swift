import SwiftUI

struct ContentView: View {
    @State private var message: String = "Waiting for message..."
    @ObservedObject var watchAccelerometer = WatchAccelerometer.shared
    @ObservedObject var watchQuaternions = WatchQuaternion.shared
    @ObservedObject var iPhoneaccelerometer = AccelerometerManager.shared
    @ObservedObject var iPhoneQuaternions = QuaternionsManager.shared
    var unlockManager = UnlockManager.shared

    var body: some View {
        VStack {
            Text("Phone unlocks: \(unlockManager.phoneUnlocks)")
        }
        .padding(10)
        VStack {
            Text("Watch accelerometer:")
            Text("Coordinates counter: \(watchAccelerometer.coordinates.count)")
            Text("X: \(watchAccelerometer.coordinates.last?.x ?? 0.0, specifier: "%.2f")")
            Text("Y: \(watchAccelerometer.coordinates.last?.y ?? 0.0, specifier: "%.2f")")
            Text("Z: \(watchAccelerometer.coordinates.last?.z ?? 0.0, specifier: "%.2f")")
            Text("Time: \(watchAccelerometer.coordinates.last?.timestamp ?? Date())")
        }
        .padding(10)
        VStack {
            Text("Watch last quaternion:")
            Text("Quaternions counter: \(watchQuaternions.quaternionHistory.count)")
            Text("W: \(watchQuaternions.quaternionHistory.last?.w ?? 0.0)")
            Text("X: \(watchQuaternions.quaternionHistory.last?.x ?? 0.0)")
            Text("Y: \(watchQuaternions.quaternionHistory.last?.y ?? 0.0)")
            Text("Z: \(watchQuaternions.quaternionHistory.last?.z ?? 0.0)")
            Text("Time: \(watchQuaternions.quaternionHistory.last?.timestamp ?? Date())")
        }
        .padding(10)
        VStack {
            Text("iPhone accelerometer:")
            Text("Y: \(iPhoneaccelerometer.coordinates.last?.x as? Double ?? 0.0, specifier: "%.2f")")
            Text("Y: \(iPhoneaccelerometer.coordinates.last?.y as? Double ?? 0.0, specifier: "%.2f")")
            Text("Z: \(iPhoneaccelerometer.coordinates.last?.z as? Double ?? 0.0, specifier: "%.2f")")
            Text("Time: \(iPhoneaccelerometer.coordinates.last?.timestamp ?? Date())")
        }
        .padding(10)
        VStack {
            Text("iPhone last quaternion:")
            Text("W: \(iPhoneQuaternions.quaternionHistory.last?.w ?? iPhoneQuaternions.quaternionHistory.last?.w ?? 0.0)")
            Text("X: \(iPhoneQuaternions.quaternionHistory.last?.x ?? iPhoneQuaternions.quaternionHistory.last?.x ?? 0.0)")
            Text("Y: \(iPhoneQuaternions.quaternionHistory.last?.y ?? iPhoneQuaternions.quaternionHistory.last?.y ?? 0.0)")
            Text("Z: \(iPhoneQuaternions.quaternionHistory.last?.z ?? iPhoneQuaternions.quaternionHistory.last?.z ?? 0.0)")
            Text("Time: \(iPhoneQuaternions.quaternionHistory.last?.timestamp ?? Date())")
        }
    }
}
