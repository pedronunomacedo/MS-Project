import UIKit
import CoreMotion
import WatchConnectivity

class ProcessQuaternions {
    static let shared = ProcessQuaternions()  // Singleton instance

    func process() -> [(watch: Quaternion, iPhone: Quaternion)]? {
        // Ensure both buffers have enough quaternions before processing (each sample corresponda to 0.02 seconds, so 200 samples correspond to 2 seconds
        if WatchQuaternion.shared.quaternionHistory.count >= 200 && QuaternionsManager.shared.quaternionHistory.count >= 200 {
            
            // 1. Apply the Gaussian filter to both sets of quaternions (watch and iPhone)
            let smoothedWatchQuaternions = gaussianFilter(quaternions: WatchQuaternion.shared.quaternionHistory, sigma: 0.03, period: 0.1)
            let smoothediPhoneQuaternions = gaussianFilter(quaternions: QuaternionsManager.shared.quaternionHistory, sigma: 0.03, period: 0.1)
            
            // 2. Align axis from the watch to the iPhone
            let normalizedWatchQuaternions = smoothedWatchQuaternions.map { $0.normalized() }
            let normalizediPhoneQuaternions = smoothediPhoneQuaternions.map { $0.normalized() }
            
            // 3. Synchronize quaternions based on their timestamps
            let alignedQuaternions = synchronizeQuaternions(normalizedWatchQuaternions, with: normalizediPhoneQuaternions)
            
            // 4. Calculate rotation quaternions to transform the watch axis into iPhone axis
            // 5. Get the aligned watch quaternion by multiplying the watch quaternions with the corresponding rotation quaternion
            var finalQuaternions: [(watch: Quaternion, iPhone: Quaternion)] = []

            for alignedQuaternion in alignedQuaternions {
                let rotationQuaternion = calculateRotationQuaternion(watchQuaternion: alignedQuaternion.watch, iPhoneQuaternion: alignedQuaternion.iPhone)
                
                // Append the aligned watch quaternion along with the corresponding iPhone quaternion
                let alignedWatchQuaternion = multiplyQuaternions(
                    q1: Quaternion(w: alignedQuaternion.watch.w, x: alignedQuaternion.watch.x, y: alignedQuaternion.watch.y, z: alignedQuaternion.watch.z, timestamp: alignedQuaternion.watch.timestamp),
                    q2: Quaternion(w: rotationQuaternion.w, x: rotationQuaternion.x, y: rotationQuaternion.y, z: rotationQuaternion.z, timestamp: alignedQuaternion.watch.timestamp)
                )
                
                finalQuaternions.append((
                    watch: Quaternion(w: alignedWatchQuaternion.w, x: alignedWatchQuaternion.x, y: alignedWatchQuaternion.y, z: alignedWatchQuaternion.z, timestamp: alignedQuaternion.watch.timestamp),
                    iPhone: Quaternion(w: alignedQuaternion.iPhone.w, x: alignedQuaternion.iPhone.x, y: alignedQuaternion.iPhone.y, z: alignedQuaternion.iPhone.z, timestamp: alignedQuaternion.iPhone.timestamp) // Include the corresponding iPhone quaternion here
                ))
            }
            
            print("alignedWatchQuaternions: ", finalQuaternions)
            
            print("---------------------------------------")
            
            return finalQuaternions
        }
        
        return nil  // Return nil if not enough data to process
    }
    
    func synchronizeQuaternions(_ watchQuaternions: [Quaternion], with iPhoneQuaternions: [Quaternion]) -> [(watch: Quaternion, iPhone: Quaternion)] {
        var alignedPairs: [(watch: Quaternion, iPhone: Quaternion)] = []
        
        for watchQuaternion in watchQuaternions {
            // Find the closest iPhone quaternion with the nearest timestamp
            if let closestiPhoneQuaternion = iPhoneQuaternions.min(by: { abs($0.timestamp.timeIntervalSince(watchQuaternion.timestamp)) < abs($1.timestamp.timeIntervalSince(watchQuaternion.timestamp)) }) {

                alignedPairs.append((watch: Quaternion(w: watchQuaternion.w, x: watchQuaternion.x, y: watchQuaternion.y, z: watchQuaternion.z, timestamp: watchQuaternion.timestamp), iPhone: Quaternion(w: closestiPhoneQuaternion.w, x: closestiPhoneQuaternion.x, y: closestiPhoneQuaternion.y, z: closestiPhoneQuaternion.z, timestamp: closestiPhoneQuaternion.timestamp)))
            }
        }
        return alignedPairs
    }
    
    func gaussianFilter(quaternions: [Quaternion], sigma: Double, period: TimeInterval) -> [Quaternion] {
        var smoothedQuaternions: [Quaternion] = []
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
            let smoothedQuaternion = Quaternion(w: normalizedQuaternion.w, x: normalizedQuaternion.x, y: normalizedQuaternion.y, z: normalizedQuaternion.z, timestamp: quaternions[i].timestamp)
            smoothedQuaternions.append(smoothedQuaternion)
        }
        
        return smoothedQuaternions
    }
    
    func normalizeQuaternions(quaternions: [Quaternion]) -> [Quaternion] {
        var normalizedQuaternions: [Quaternion] = []
        
        for var quaternion in quaternions {
            // Calculate the magnitude of the quaternion (w^2 + x^2 + y^2 + z^2)
            let magnitude = sqrt(quaternion.w * quaternion.w + quaternion.x * quaternion.x + quaternion.y * quaternion.y + quaternion.z * quaternion.z)
            
            // Normalize the quaternion (w, x, y, z)
            if magnitude != 0 {
                quaternion.w /= magnitude
                quaternion.x /= magnitude
                quaternion.y /= magnitude
                quaternion.z /= magnitude
            }
            
            // Append the normalized quaternion to the result list
            let quaternionObj = Quaternion(w: quaternion.w, x: quaternion.x, y: quaternion.y, z: quaternion.z, timestamp: quaternion.timestamp)
            normalizedQuaternions.append(quaternionObj)
        }
        
        return normalizedQuaternions
    }
    
    func invertQuaternions(quaternion: Quaternion) -> Quaternion {
        return Quaternion(w: quaternion.w, x: -quaternion.x, y: -quaternion.y, z: -quaternion.z, timestamp: quaternion.timestamp)
    }
    
    func multiplyQuaternions(q1: Quaternion, q2: Quaternion) -> Quaternion {
        
            let w = q1.w * q2.w - q1.x * q2.x - q1.y * q2.y - q1.z * q2.z
            let x = q1.w * q2.x + q1.x * q2.w + q1.y * q2.z - q1.z * q2.y
            let y = q1.w * q2.y - q1.x * q2.z + q1.y * q2.w + q1.z * q2.x
            let z = q1.w * q2.z + q1.x * q2.y - q1.y * q2.x + q1.z * q2.w
            
            // Return the resulting quaternion along with the timestamp of q2 (or q1, since they're typically synced)
        return Quaternion(w: w, x: x, y: y, z: z)
    }
    
    func calculateRotationQuaternion(watchQuaternion: Quaternion, iPhoneQuaternion: Quaternion) -> Quaternion {
        // Invert the iPhone quaternion
        let invertediPhoneQuaternion = invertQuaternions(quaternion: iPhoneQuaternion)
        
        // Multiply the watch quaternion with the inverted iPhone quaternion to calculate the rotation
        return multiplyQuaternions(q1: watchQuaternion, q2: invertediPhoneQuaternion)
    }

    func alignQuaternions(_ quaternions: [Quaternion]) -> [Quaternion] {
        var alignedQuaternions: [Quaternion] = [quaternions[0]]
        
        for i in 1..<quaternions.count {
            var currentQuaternion = quaternions[i]
            let previousQuaternion = alignedQuaternions.last!
            
            let dotProduct = previousQuaternion.w * currentQuaternion.w + previousQuaternion.x * currentQuaternion.x + previousQuaternion.y * currentQuaternion.y + previousQuaternion.z * currentQuaternion.z
            
            if dotProduct < 0 {
                currentQuaternion = Quaternion(w: -currentQuaternion.w, x: -currentQuaternion.x, y: -currentQuaternion.y, z: -currentQuaternion.z, timestamp: currentQuaternion.timestamp)
            }
            
            alignedQuaternions.append(currentQuaternion)
        }
        
        return alignedQuaternions
    }

    // Function to check if quaternions are aligned based on an angular difference threshold
    func areQuaternionsAligned(q1: Quaternion, q2: Quaternion, threshold: Double = 0.087) -> Bool { // Threshold is in radians: 0.087 radians = 5 degrees
        let angularDifference = calculateAngularDifference(q1: q1, q2: q2)
        
        print("angularDifference: ", angularDifference)
                
        return (angularDifference <= threshold)
    }
    
    // Function to calculate angular difference between two quaternions
    func calculateAngularDifference(q1: Quaternion, q2: Quaternion) -> Double {
        // Calculate the dot product between the two quaternions
        let dotProduct = q1.w * q2.w + q1.x * q2.x + q1.y * q2.y + q1.z * q2.z
        
        // Ensure the dot product is within the valid range for acos
        let clampedDot = min(max(dotProduct, -1.0), 1.0)
        
        // Calculate the angular difference (in radians)
        let angularDifference = 2 * acos(clampedDot)
        
        return angularDifference // Angular difference in radians
    }
    
    // Function to normalize a quaternion
    func normalizeQuaternion(quaternion: Quaternion) -> Quaternion {
        let norm = sqrt(quaternion.w * quaternion.w + quaternion.x * quaternion.x + quaternion.y * quaternion.y + quaternion.z * quaternion.z)
        
        // If the norm is 0 (which shouldn't happen for valid quaternions), return the original quaternion
        guard norm != 0 else { return quaternion }
        
        return Quaternion(
            w: quaternion.w / norm,
            x: quaternion.x / norm,
            y: quaternion.y / norm,
            z: quaternion.z / norm
        )
    }
    
    // Function to calculate the change in orientation (Δq)
    func calculateDeltaQ(quaternionAtT: Quaternion, quaternionAtTPlusAlpha: Quaternion) -> Quaternion {
        // Calculate the inverse of the quaternion at time t
        let inverseAtT = inverseQuaternion(quaternionAtT)
        
        // Multiply quaternions
        let multipliedQuaternion = multiplyQuaternions(q1: quaternionAtTPlusAlpha, q2: inverseAtT)
            
        // Multiply the quaternion at time t+alpha by the inverse of the quaternion at time t
        return Quaternion(w: multipliedQuaternion.w, x: multipliedQuaternion.x, y: multipliedQuaternion.y, z: multipliedQuaternion.z, timestamp: quaternionAtT.timestamp)
    }
    
    // Function to calculate the inverse of a quaternion
    func inverseQuaternion(_ quaternion: Quaternion) -> Quaternion {
        return Quaternion(w: quaternion.w, x: -quaternion.x, y: -quaternion.y, z: -quaternion.z)
    }
    
    // Function that checks if the minimum required of samples sync number is reached to unlock the iPhone with the Apple watch
    func verifyAlignment(with alignedQuaternions: [(watch: Quaternion, iPhone: Quaternion)]) -> Bool {
        print("Verifying quaternions alignment!")
        let alignmentThreshold = 0.1  // Define your threshold for angular alignment
        let consistentSamplesRequired = 75  // 1.5 seconds of consistent alignment at 0.02-second intervals
        
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
