import Foundation

struct Acceleration {
    var x: Double
    var y: Double
    var z: Double
    var timestamp: TimeInterval  // Timestamp for each acceleration instance

    // Initialize with components and optional timestamp
    init(x: Double, y: Double, z: Double, timestamp: TimeInterval = Date().timeIntervalSince1970) {
        self.x = x
        self.y = y
        self.z = z
        self.timestamp = timestamp
    }
    
    // Compute the magnitude of the acceleration
    func magnitude() -> Double {
        return sqrt(x * x + y * y + z * z)
    }
    
    // Normalizes the acceleration vector
    func normalized() -> Acceleration {
        let mag = magnitude()
        return Acceleration(x: x / mag, y: y / mag, z: z / mag, timestamp: timestamp)
    }
}
