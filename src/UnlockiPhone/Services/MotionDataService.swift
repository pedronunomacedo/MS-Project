import Foundation
import CoreMotion

class MotionDataService: ObservableObject {
    static let shared = MotionDataService()
    
    private let motionManager = CMMotionManager()
    private let updateInterval = 1.0 / 10.0 // 10Hz (0.1 seconds per sample - 10 samples per second)
    
    public var motionProcessor = MotionDataProcessor.shared
    
    private var accelerationBuffer: [Acceleration] = []
    private var quaternionBuffer: [Quaternion] = []
    
        
    init() {
        // setupMotionUpdates()
    }
    
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
            
            // Collect accelerometer data
            let accelerationData = deviceMotion.userAcceleration
            let acceleration = Acceleration(x: accelerationData.x, y: accelerationData.y, z: accelerationData.z)
            
            self.motionProcessor.addData(source: "iPhone", accelerations: [acceleration], quaternions: [quaternion])
        }
    }
    
    func getBufferedAccelerations() -> [Acceleration] {
        return accelerationBuffer
    }
    
    func getBufferedQuaternions() -> [Quaternion] {
        return quaternionBuffer
    }
    
    func stopUpdates() {
        motionManager.stopDeviceMotionUpdates()
    }
}
