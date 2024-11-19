import WatchKit
import CoreMotion

class Accelerometer: NSObject {
    var delegate = ExtensionDelegate.shared
    
    static let shared = Accelerometer()
    private var motion = CMMotionManager()
    private var timer: Timer?
    @Published var isAccelerometerAvailable: Bool = true
    
    public private(set) var coordinates: [String: Any] = ["x": 0.0, "y": 0.0, "z": 0.0, "timestamp": Date()]
    public var strCoordinates: String = ""

    override init() {
        super.init()
        startAccelerometers()
    }
    
    func startAccelerometers() {
        // Check if the accelerometer hardware is available.
        if self.motion.isAccelerometerAvailable {
            self.motion.accelerometerUpdateInterval = 1.0 / 1.0  // 1 Hz

            // Start accelerometer updates and handle them with a closure.
            self.motion.startAccelerometerUpdates(to: .main) { [weak self] (data, error) in
                guard let strongSelf = self, let accelerometerData = data else {
                    print("Error: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                let x = accelerometerData.acceleration.x
                let y = accelerometerData.acceleration.y
                let z = accelerometerData.acceleration.z
                let currentTimestamp = Date()
                
                // Ensure updates to published properties are handled on the main thread
                DispatchQueue.main.async {
                    strongSelf.updateCoordinates(x: x, y: y, z: z, timestamp: currentTimestamp)
                    strongSelf.delegate.sendMessage(content: ["coordinates": strongSelf.coordinates])
                }
            }
        } else {
            print("Accelerometer is not available on this device.")
            self.isAccelerometerAvailable = false
        }
    }
    
    func updateCoordinates(x: Double, y: Double, z: Double, timestamp: Date) {
        self.coordinates["x"] = x
        self.coordinates["y"] = y
        self.coordinates["z"] = z
        self.coordinates["timestamp"] = timestamp
    }
    
    deinit {
        // Stop the accelerometer and invalidate the timer when the object is deinitialized.
        motion.stopAccelerometerUpdates()
        timer?.invalidate()
    }
}
