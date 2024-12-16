import Foundation
import CoreMotion

class ProcessAcceleration {
    static let shared = ProcessAcceleration()  // Singleton instance
    
    func verifyStability(with alignedAccelerations: [(watch: Acceleration, iPhone: Acceleration)]) -> Bool {
        print("Verifying accelerations stability!")
        let alignmentThreshold = 0.1  // Define your threshold for angular alignment
        let consistentSamplesRequired = 75  // 1.5 seconds of consistent alignment at 1 second intervals
        
        var consistentAlignmentCount = 0
        
        for i in 0..<alignedAccelerations.count - 1 {
            // Calculate Δq for both watch and iPhone accelerations at each time step
            let deltaAWatch = calculateDeltaA(accelerationAtT: alignedAccelerations[i].watch, accelerationAtTPlusAlpha: alignedAccelerations[i + 1].watch)
            let deltaAiPhone = calculateDeltaA(accelerationAtT: alignedAccelerations[i].iPhone, accelerationAtTPlusAlpha: alignedAccelerations[i + 1].iPhone)
            
            print("consistentAlignmentCount: ", consistentAlignmentCount)
            // Check if the acellerations are aligned within the threshold
            if areAccelerationsAligned(a1: deltaAWatch, a2: deltaAiPhone, threshold: alignmentThreshold) {
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
    
    func process() -> [(watch: Acceleration, iPhone: Acceleration)]? {
        // Ensure both buffers have enough accelerations before processing (each sample corresponda to 0.02 seconds, so 200 samples correspond to 4 seconds)
        if WatchAccelerometer.shared.coordinates.count == 200 && AccelerometerManager.shared.coordinates.count == 200 {
            
            // 1. Apply the Gaussian filter to both sets of accelerations (watch and iPhone)
            let smoothedWatchAccelerations = gaussianFilter(accelerations: WatchAccelerometer.shared.coordinates, sigma: 0.03, period: 0.1)
            let smoothediPhoneAccelerations = gaussianFilter(accelerations: AccelerometerManager.shared.coordinates, sigma: 0.03, period: 0.1)
            
            // 2. Synchronize accelerations based on their timestamps
            let alignedAccelerations = synchronizeAccelerations(watchAccelerations: smoothedWatchAccelerations, with: smoothediPhoneAccelerations)
            
            return alignedAccelerations
        }
        
        return nil  // Return nil if not enough data to process
    }
    
    func areAccelerationsAligned(a1: Acceleration, a2: Acceleration, threshold: Double = 0.1) -> Bool {
        // Check if the difference in acceleration components is within the threshold
        let deltaX = abs(a1.x - a2.x)
        let deltaY = abs(a1.y - a2.y)
        let deltaZ = abs(a1.z - a2.z)
        
        return (deltaX <= threshold && deltaY <= threshold && deltaZ <= threshold)
    }
    
    func gaussianFilter(accelerations: [Acceleration], sigma: Double, period: TimeInterval) -> [Acceleration] {
        var smoothedAccelerations: [Acceleration] = []
        let gaussianWindowSize = Int(period / 0.1)
        
        for i in 0..<accelerations.count {
            var sumWeights = 0.0
            var weightedAcceleration = CMAcceleration(x: 0, y: 0, z: 0)
            
            for j in max(0, i - gaussianWindowSize)...min(accelerations.count - 1, i + gaussianWindowSize) {
                let timeDifference = abs(accelerations[j].timestamp.timeIntervalSince(accelerations[i].timestamp))
                let weight = exp(-(timeDifference * timeDifference) / (2 * sigma * sigma))
                
                weightedAcceleration.x += weight * accelerations[j].x
                weightedAcceleration.y += weight * accelerations[j].y
                weightedAcceleration.z += weight * accelerations[j].z
                sumWeights += weight
            }
            
            let normalizedAcceleration = CMAcceleration(x: weightedAcceleration.x / sumWeights, y: weightedAcceleration.y / sumWeights, z: weightedAcceleration.z / sumWeights)
            smoothedAccelerations.append(Acceleration(x: normalizedAcceleration.x, y: normalizedAcceleration.y, z: normalizedAcceleration.z, timestamp: accelerations[i].timestamp))
        }
        
        return smoothedAccelerations
    }
    
    // Function to calculate the change in orientation (Δq)
    func calculateDeltaA(accelerationAtT: Acceleration, accelerationAtTPlusAlpha: Acceleration) -> Acceleration {
        // Subtract the acceleration at time t+alpha by the inverse of the acceleration at time t
        return Acceleration(
            x: accelerationAtTPlusAlpha.x - accelerationAtT.x,
            y: accelerationAtTPlusAlpha.y - accelerationAtT.y,
            z: accelerationAtTPlusAlpha.z - accelerationAtT.z,
            timestamp: accelerationAtT.timestamp
        )
    }
    
    func synchronizeAccelerations(watchAccelerations: [Acceleration], with iPhoneAccelerations: [Acceleration]) -> [(watch: Acceleration, iPhone: Acceleration)] {
        var alignedPairs: [(watch: Acceleration, iPhone: Acceleration)] = []
        
        for watchAcceleration in watchAccelerations {
            // Find the closest iPhone acceleration with the nearest timestamp
            if let closestiPhoneAcceleration = iPhoneAccelerations.min(by: { abs($0.timestamp.timeIntervalSince(watchAcceleration.timestamp)) < abs($1.timestamp.timeIntervalSince(watchAcceleration.timestamp)) }) {
                
                alignedPairs.append((watch: watchAcceleration, iPhone: Acceleration(x: closestiPhoneAcceleration.x, y: closestiPhoneAcceleration.y, z: closestiPhoneAcceleration.z, timestamp: closestiPhoneAcceleration.timestamp)))
            }
        }
        return alignedPairs
    }
}
