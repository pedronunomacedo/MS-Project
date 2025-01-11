import Foundation
import CoreMotion

class MotionDataService: ObservableObject {
    private let motionManager = CMMotionManager()
    private let updateInterval = 1.0 / 10.0 // 10Hz (0.1 seconds per sample - 10 samples per second)
    
    @Published var accelerationBuffer: [Acceleration] = [Acceleration]()
    @Published var quaternionBuffer: [Quaternion] = [Quaternion]()
    
    // Callback for sending data
    var onBatchReady: (([Acceleration], [Quaternion]) -> Void)?
    
    public func setupMotionUpdates() {
        guard motionManager.isDeviceMotionAvailable else {
            print("Device Motion is not available.")
            return
        }
        
        motionManager.deviceMotionUpdateInterval = updateInterval
        
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] deviceMotion, error in
            guard let self = self, let deviceMotion = deviceMotion, error == nil else {
                if let error = error {
                    print("Device motion error: \(error.localizedDescription)")
                }
                return
            }
            
            // Collect quaternion data
            let attitude = deviceMotion.attitude.quaternion
            let quaternion = Quaternion(w: attitude.w, x: attitude.x, y: attitude.y, z: attitude.z)
            self.quaternionBuffer.append(quaternion)
            
            // Collect accelerometer data
            let accelerationData = deviceMotion.userAcceleration
            let acceleration = Acceleration(x: accelerationData.x, y: accelerationData.y, z: accelerationData.z)
            self.accelerationBuffer.append(acceleration)
            
            print("Adding acceleration!")
            
            // Check if both buffers have 20 samples (2 seconds)
            if self.accelerationBuffer.count >= 20 && self.quaternionBuffer.count >= 20 {
                self.sendBatch()
            }
        }
    }
    
    private func sendBatch() {
        let accelerations = Array(accelerationBuffer.prefix(20))
        let quaternions = Array(quaternionBuffer.prefix(20))
        
        // Trigger the callback to send data
        onBatchReady?(accelerations, quaternions)
        
        // Clear the buffers
        accelerationBuffer.removeFirst(20)
        quaternionBuffer.removeFirst(20)
    }
    
    public func stopUpdates() {
        motionManager.stopDeviceMotionUpdates()
    }
}
