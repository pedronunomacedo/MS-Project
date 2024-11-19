import UIKit
import CoreMotion
import WatchConnectivity

class ProcessQuaternions {
    static let shared = ProcessQuaternions()  // Singleton instance

    func process() -> [(watch: (Double, Double, Double, Double), iPhone: (Double, Double, Double, Double))]? {
        // Ensure both buffers have enough quaternions before processing
        if WatchQuaternion.shared.quaternionHistory.count >= 50 && QuaternionsManager.shared.quaternionHistory.count >= 50 {
            
            // 1. Apply the Gaussian filter to both sets of quaternions (watch and iPhone)
            let smoothedWatchQuaternions = gaussianFilter(quaternions: WatchQuaternion.shared.quaternionHistory, sigma: 0.03, period: 0.1)
            let smoothediPhoneQuaternions = gaussianFilter(quaternions: QuaternionsManager.shared.quaternionHistory, sigma: 0.03, period: 0.1)
            
            // 2. Synchronize quaternions based on their timestamps
            let alignedQuaternions = synchronizeQuaternions(smoothedWatchQuaternions, with: smoothediPhoneQuaternions)

//            // 3. Calculate Δq for the aligned quaternions
//            for i in 0..<alignedQuaternions.count - 1 {
//                let deltaQWatch = calculateDeltaQ(quaternionAtT: alignedQuaternions[i].watch, quaternionAtTPlusAlpha: alignedQuaternions[i + 1].watch)
//                let deltaQiPhone = calculateDeltaQ(quaternionAtT: alignedQuaternions[i].iPhone, quaternionAtTPlusAlpha: alignedQuaternions[i + 1].iPhone)
//            }
            
            return alignedQuaternions
        }
        
        return nil  // Return nil if not enough data to process
    }
    
    func synchronizeQuaternions(_ watchQuaternions: [(w: Double, x: Double, y: Double, z: Double, timestamp: Date)], with iPhoneQuaternions: [(w: Double, x: Double, y: Double, z: Double, timestamp: Date)]) -> [(watch: (Double, Double, Double, Double), iPhone: (Double, Double, Double, Double))] {
        var alignedPairs: [(watch: (Double, Double, Double, Double), iPhone: (Double, Double, Double, Double))] = []
        
        for watchQuaternion in watchQuaternions {
            // Find the closest iPhone quaternion with the nearest timestamp
            if let closestiPhoneQuaternion = iPhoneQuaternions.min(by: { abs($0.timestamp.timeIntervalSince(watchQuaternion.timestamp)) < abs($1.timestamp.timeIntervalSince(watchQuaternion.timestamp)) }) {
                alignedPairs.append((watch: (watchQuaternion.w, watchQuaternion.x, watchQuaternion.y, watchQuaternion.z), iPhone: (closestiPhoneQuaternion.w, closestiPhoneQuaternion.x, closestiPhoneQuaternion.y, closestiPhoneQuaternion.z)))
            }
        }
        return alignedPairs
    }
    
    func gaussianFilter(quaternions: [(w: Double, x: Double, y: Double, z: Double, timestamp: Date)], sigma: Double, period: TimeInterval) -> [(w: Double, x: Double, y: Double, z: Double, timestamp: Date)] {
        var smoothedQuaternions: [(w: Double, x: Double, y: Double, z: Double, timestamp: Date)] = []
        let gaussianWindowSize = Int(period / 0.1)
        
        for i in 0..<quaternions.count {
            var sumWeights = 0.0
            var weightedQuaternion = CMQuaternion(x: 0, y: 0, z: 0, w: 0)
            
            for j in max(0, i - gaussianWindowSize)...min(quaternions.count - 1, i + gaussianWindowSize) {
                let timeDifference = abs(quaternions[j].timestamp.timeIntervalSince(quaternions[i].timestamp))
                let weight = exp(-(timeDifference * timeDifference) / (2 * sigma * sigma))
                
                weightedQuaternion.x += weight * quaternions[j].x
                weightedQuaternion.y += weight * quaternions[j].y
                weightedQuaternion.z += weight * quaternions[j].z
                weightedQuaternion.w += weight * quaternions[j].w
                sumWeights += weight
            }
            
            let normalizedQuaternion = CMQuaternion(x: weightedQuaternion.x / sumWeights, y: weightedQuaternion.y / sumWeights, z: weightedQuaternion.z / sumWeights, w: weightedQuaternion.w / sumWeights)
            smoothedQuaternions.append((w: normalizedQuaternion.w, x: normalizedQuaternion.x, y: normalizedQuaternion.y, z: normalizedQuaternion.z, timestamp: quaternions[i].timestamp))
        }
        
        return smoothedQuaternions
    }

    func alignQuaternions(_ quaternions: [(w: Double, x: Double, y: Double, z: Double, timestamp: Date)]) -> [(w: Double, x: Double, y: Double, z: Double, timestamp: Date)] {
        var alignedQuaternions: [(w: Double, x: Double, y: Double, z: Double, timestamp: Date)] = [quaternions[0]]
        
        for i in 1..<quaternions.count {
            var currentQuaternion = quaternions[i]
            let previousQuaternion = alignedQuaternions.last!
            
            let dotProduct = previousQuaternion.w * currentQuaternion.w + previousQuaternion.x * currentQuaternion.x + previousQuaternion.y * currentQuaternion.y + previousQuaternion.z * currentQuaternion.z
            
            if dotProduct < 0 {
                currentQuaternion = (w: -currentQuaternion.w, x: -currentQuaternion.x, y: -currentQuaternion.y, z: -currentQuaternion.z, timestamp: currentQuaternion.timestamp)
            }
            
            alignedQuaternions.append(currentQuaternion)
        }
        
        return alignedQuaternions
    }

    // Function to check if quaternions are aligned based on an angular difference threshold
    func areQuaternionsAligned(q1: (w: Double, x: Double, y: Double, z: Double), q2: (w: Double, x: Double, y: Double, z: Double), threshold: Double = 0.1) -> Bool {
        let angularDifference = calculateAngularDifference(q1: q1, q2: q2)
                
        return (angularDifference <= threshold)
    }
    
    // Function to calculate angular difference between two quaternions
    func calculateAngularDifference(q1: (w: Double, x: Double, y: Double, z: Double), q2: (w: Double, x: Double, y: Double, z: Double)) -> Double {
        // Calculate the dot product between the two quaternions
        let dotProduct = q1.w * q2.w + q1.x * q2.x + q1.y * q2.y + q1.z * q2.z
        
        // Ensure the dot product is within the valid range for acos
        let clampedDot = min(max(dotProduct, -1.0), 1.0)
        
        // Calculate the angular difference (in radians)
        let angularDifference = 2 * acos(clampedDot)
        
        return angularDifference // Angular difference in radians
    }
    
    // Function to normalize a quaternion
    func normalizeQuaternion(_ quaternion: (w: Double, x: Double, y: Double, z: Double)) -> (w: Double, x: Double, y: Double, z: Double) {
        let norm = sqrt(quaternion.w * quaternion.w + quaternion.x * quaternion.x + quaternion.y * quaternion.y + quaternion.z * quaternion.z)
        
        // If the norm is 0 (which shouldn't happen for valid quaternions), return the original quaternion
        guard norm != 0 else { return quaternion }
        
        return (
            w: quaternion.w / norm,
            x: quaternion.x / norm,
            y: quaternion.y / norm,
            z: quaternion.z / norm
        )
    }
    
    // Function to calculate the change in orientation (Δq)
    func calculateDeltaQ(quaternionAtT: (w: Double, x: Double, y: Double, z: Double), quaternionAtTPlusAlpha: (w: Double, x: Double, y: Double, z: Double)) -> (w: Double, x: Double, y: Double, z: Double) {
        // Calculate the inverse of the quaternion at time t
        let inverseAtT = inverseQuaternion(quaternionAtT)
            
        // Multiply the quaternion at time t+alpha by the inverse of the quaternion at time t
        return multiplyQuaternions(quaternionAtTPlusAlpha, inverseAtT)
    }
    
    // Function to calculate the inverse of a quaternion
    func inverseQuaternion(_ quaternion: (w: Double, x: Double, y: Double, z: Double)) -> (w: Double, x: Double, y: Double, z: Double) {
        return (w: quaternion.w, x: -quaternion.x, y: -quaternion.y, z: -quaternion.z)
    }
    
    // Function to multiply two quaternions
    func multiplyQuaternions(_ q1: (w: Double, x: Double, y: Double, z: Double), _ q2: (w: Double, x: Double, y: Double, z: Double)) -> (w: Double, x: Double, y: Double, z: Double) {
        return (
            w: q1.w * q2.w - q1.x * q2.x - q1.y * q2.y - q1.z * q2.z,
            x: q1.w * q2.x + q1.x * q2.w + q1.y * q2.z - q1.z * q2.y,
            y: q1.w * q2.y - q1.x * q2.z + q1.y * q2.w + q1.z * q2.x,
            z: q1.w * q2.z + q1.x * q2.y - q1.y * q2.x + q1.z * q2.w
        )
    }
    
    // Function that checks if the minimum required of samples sync number is reached to unlock the iPhone with the Apple watch
    func verifyAlignment(with alignedQuaternions: [(watch: (Double, Double, Double, Double), iPhone: (Double, Double, Double, Double))]) -> Bool {
        print("Verifying quaternions alignment!")
        let alignmentThreshold = 0.1  // Define your threshold for angular alignment
        let consistentSamplesRequired = 5  // 5 seconds of consistent alignment at 0.1-second intervals
        
        var consistentAlignmentCount = 0
        
        for i in 0..<alignedQuaternions.count - 1 {
            // Calculate Δq for both watch and iPhone quaternions at each time step
            let deltaQWatch = calculateDeltaQ(quaternionAtT: alignedQuaternions[i].watch, quaternionAtTPlusAlpha: alignedQuaternions[i + 1].watch)
            let deltaQiPhone = calculateDeltaQ(quaternionAtT: alignedQuaternions[i].iPhone, quaternionAtTPlusAlpha: alignedQuaternions[i + 1].iPhone)
            
            print("consistentAlignmentCount: ", consistentAlignmentCount)
            // Check if the quaternions are aligned within the threshold
            if areQuaternionsAligned(q1: deltaQWatch, q2: deltaQiPhone, threshold: alignmentThreshold) {
                consistentAlignmentCount += 1
            } else {
                consistentAlignmentCount = 0  // Reset count if alignment is broken
            }
            
            // Unlock condition: enough consistent alignments
            if consistentAlignmentCount >= consistentSamplesRequired {
                return true  // Unlock condition met
            }
        }
        return false  // Unlock condition not met
    }
}
