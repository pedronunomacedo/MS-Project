import WatchKit
import CoreMotion

class Quaternions: NSObject {
    var delegate = ExtensionDelegate.shared
    
    static let shared = Quaternions()
    private var motion = CMMotionManager()
    private var timer: Timer?
    @Published var isAccelerometerAvailable: Bool = true
    
    public private(set) var quaternionHistory: [(w: Double, x: Double, y: Double, z: Double, timestamp: Date)] = [] // Current Apple watch coordinates
    public var strCoordinates: String = ""

    override init() {
        super.init()
        startQuaternions()
    }
    
    func startQuaternions() {
        // Check if the accelerometer hardware is available.
        if self.motion.isAccelerometerAvailable {
            self.motion.deviceMotionUpdateInterval = 1.0 / 50.0  // 50 Hz

            // Start device motion updates
            self.motion.startDeviceMotionUpdates(to: .main) { [weak self] (motionData, error) in
                guard let strongSelf = self, let motion = motionData else {
                    print("Error: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }

                // Collect quaternion data
                let quaternion = motion.attitude.quaternion
                let w = quaternion.w
                let x = quaternion.x
                let y = quaternion.y
                let z = quaternion.z
                let currentTimestamp = Date()
                
                // Store the quaternion in the history array
                DispatchQueue.main.async {
                    strongSelf.updateQuaternions(w: w, x: x, y: y, z: z, timestamp: currentTimestamp)
                    
                    strongSelf.delegate.sendMessage(content: ["quaternions": strongSelf.to_dict()]) // Send quartenions history (max of 50 quaternions records)
                }
            }
        } else {
            print("Accelerometer is not available on this device.")
            self.isAccelerometerAvailable = false
        }
    }
    
    func updateQuaternions(w: Double, x: Double, y: Double, z: Double, timestamp: Date) {
        self.quaternionHistory.append((w, x, y, z, timestamp))
        
        // Limit the history size to save memory (we will only keep the last 200 quaternions) (0.02 * 200 = 4 seconds)
        if self.quaternionHistory.count > 200 {
            self.quaternionHistory.removeFirst()
        }
    }
    
    func to_dict() -> [[String: Double]] {
        return self.quaternionHistory.map { quaternion in
            [
                "w": quaternion.w,
                "x": quaternion.x,
                "y": quaternion.y,
                "z": quaternion.z,
                "timestamp": quaternion.timestamp.timeIntervalSince1970 // Convert Date to timestamp
            ]
        }
    }
    
    deinit {
        // Stop the accelerometer and invalidate the timer when the object is deinitialized.
        motion.stopAccelerometerUpdates()
        timer?.invalidate()
    }
}
