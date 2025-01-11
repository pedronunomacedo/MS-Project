import Foundation

struct Quaternion {
    var w: Double
    var x: Double
    var y: Double
    var z: Double
    var timestamp: TimeInterval  // Timestamp for each quaternion instance

    // Initialize with components and optional timestamp
    init(w: Double, x: Double, y: Double, z: Double, timestamp: TimeInterval = Date().timeIntervalSince1970) {
        self.w = w
        self.x = x
        self.y = y
        self.z = z
        self.timestamp = timestamp
    }

    // Quaternion multiplication with another Quaternion
    static func *(lhs: Quaternion, rhs: Quaternion) -> Quaternion {
        return Quaternion(
            w: lhs.w * rhs.w - lhs.x * rhs.x - lhs.y * rhs.y - lhs.z * rhs.z,
            x: lhs.w * rhs.x + lhs.x * rhs.w + lhs.y * rhs.z - lhs.z * rhs.y,
            y: lhs.w * rhs.y - lhs.x * rhs.z + lhs.y * rhs.w + lhs.z * rhs.x,
            z: lhs.w * rhs.z + lhs.x * rhs.y - lhs.y * rhs.x + lhs.z * rhs.w,
            timestamp: lhs.timestamp // Use timestamp from 'left' quaternion
        )
    }
    
    // Quaternion multiplication with a scalar
    static func *(lhs: Quaternion, rhs: Double) -> Quaternion {
        return Quaternion(w: lhs.w * rhs, x: lhs.x * rhs, y: lhs.y * rhs, z: lhs.z * rhs)
    }
    
    static func +(lhs: Quaternion, rhs: Quaternion) -> Quaternion {
        return Quaternion(w: lhs.w + rhs.w, x: lhs.x + rhs.x, y: lhs.y + rhs.y, z: lhs.z + rhs.z)
    }
    
    // Quaternion conjugate
    func conjugate() -> Quaternion {
        return Quaternion(w: w, x: -x, y: -y, z: -z)
    }
    
    // Compute the magnitude of the acceleration
    func magnitude() -> Double {
        return sqrt(w * w + x * x + y * y + z * z)
    }
    
    // Normalize quaternion
    func normalized() -> Quaternion {
        let magnitude = self.magnitude()
        return Quaternion(w: w / magnitude, x: x / magnitude, y: y / magnitude, z: z / magnitude)
    }
    
    // Flip the quaternion (negate all components)
    func flipped() -> Quaternion {
        return Quaternion(w: -w, x: -x, y: -y, z: -z)
    }
    
    // Dot product between two quaternions
    func dot(with other: Quaternion) -> Double {
        return w * other.w + x * other.x + y * other.y + z * other.z
    }
    
    func inverse() -> Quaternion? {
        let normSq = self.w * self.w + self.x * self.x + self.y * self.y + self.z * self.z
        guard normSq != 0 else { return nil } // Avoid division by zero
        
        return Quaternion(w: self.w, x: -self.x, y: -self.y, z: -self.z) * (1.0 / normSq)
    }
}


// Function to ensure shortest interpolation path
func ensureShortestPath(quaternions: [Quaternion]) -> [Quaternion] {
    var adjustedQuaternions = [Quaternion]()
    guard let firstQuaternion = quaternions.first else { return adjustedQuaternions }

    var prevQuaternion = firstQuaternion
    adjustedQuaternions.append(firstQuaternion)

    for i in 1..<quaternions.count {
        let currentQuaternion = quaternions[i]
        // Check dot product: if negative, flip the quaternion
        if prevQuaternion.dot(with: currentQuaternion) < 0 {
            adjustedQuaternions.append(currentQuaternion.flipped())
        } else {
            adjustedQuaternions.append(currentQuaternion)
        }
        prevQuaternion = adjustedQuaternions.last!
    }

    return adjustedQuaternions
}
