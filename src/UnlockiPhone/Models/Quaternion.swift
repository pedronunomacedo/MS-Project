import Foundation

struct Quaternion {
    var w: Double
    var x: Double
    var y: Double
    var z: Double
    var timestamp: Date  // Timestamp for each quaternion instance

    // Initialize with components and optional timestamp
    init(w: Double, x: Double, y: Double, z: Double, timestamp: Date = Date()) {
        self.w = w
        self.x = x
        self.y = y
        self.z = z
        self.timestamp = timestamp
    }

    // Compute the magnitude (norm) of the quaternion
    func norm() -> Double {
        return sqrt(w * w + x * x + y * y + z * z)
    }

    // Normalize the quaternion to make it a unit quaternion
    func normalized() -> Quaternion {
        let magnitude = norm()
        return Quaternion(w: w / magnitude, x: x / magnitude, y: y / magnitude, z: z / magnitude, timestamp: timestamp)
    }

    // Dot product of two quaternions
    static func dotProduct(_ q1: Quaternion, _ q2: Quaternion) -> Double {
        return q1.w * q2.w + q1.x * q2.x + q1.y * q2.y + q1.z * q2.z
    }

    // Multiplication of two quaternions
    static func *(left: Quaternion, right: Quaternion) -> Quaternion {
        let w = left.w * right.w - left.x * right.x - left.y * right.y - left.z * right.z
        let x = left.w * right.x + left.x * right.w + left.y * right.z - left.z * right.y
        let y = left.w * right.y - left.x * right.z + left.y * right.w + left.z * right.x
        let z = left.w * right.z + left.x * right.y - left.y * right.x + left.z * right.w
        return Quaternion(w: w, x: x, y: y, z: z, timestamp: left.timestamp)  // Use timestamp from 'left' quaternion
    }
}
