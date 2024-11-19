import Foundation
import CoreMotion

class ProcessAcceleration {
    static let shared = ProcessAcceleration()  // Singleton instance
    
    func verifyStability(with alignedAccelerations: [(watch: (Double, Double, Double), iPhone: (Double, Double, Double))]) -> Bool {
        print("Verifying accelerations stability!")
        let alignmentThreshold = 0.1  // Define your threshold for angular alignment
        let consistentSamplesRequired = 100  // 2 seconds of consistent alignment at 1 second intervals
        
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
    
    func process() -> [(watch: (Double, Double, Double), iPhone: (Double, Double, Double))]? {
        // Ensure both buffers have enough accelerations before processing (each sample corresponda to 0.02 seconds, so 100 samples correspond to 2 seconds)
        if WatchAccelerometer.shared.coordinates.count >= 100 && AccelerometerManager.shared.coordinates.count >= 100 {
            
            // 1. Apply the Gaussian filter to both sets of accelerations (watch and iPhone)
            let smoothedWatchAccelerations = gaussianFilter(accelerations: WatchAccelerometer.shared.coordinates, sigma: 0.03, period: 0.1)
            let smoothediPhoneAccelerations = gaussianFilter(accelerations: AccelerometerManager.shared.coordinates, sigma: 0.03, period: 0.1)
            
            // 2. Synchronize accelerations based on their timestamps
            let alignedAccelerations = synchronizeAccelerations(smoothedWatchAccelerations, with: smoothediPhoneAccelerations)

//            // 3. Calculate Δq for the aligned accelerations
//            for i in 0..<alignedAccelerations.count - 1 {
//                let deltaAWatch = calculateDeltaA(accelerationAtT: alignedAccelerations[i].watch, accelerationAtTPlusAlpha: alignedAccelerations[i + 1].watch)
//                let deltaAiPhone = calculateDeltaA(accelerationAtT: alignedAccelerations[i].iPhone, accelerationAtTPlusAlpha: alignedAccelerations[i + 1].iPhone)
//            }
            
            return alignedAccelerations
        }
        
        return nil  // Return nil if not enough data to process
    }
    
    func areAccelerationsAligned(a1: (x: Double, y: Double, z: Double), a2: (x: Double, y: Double, z: Double), threshold: Double = 0.1) -> Bool {
        // Check if the difference in acceleration components is within the threshold
        let deltaX = abs(a1.x - a2.x)
        let deltaY = abs(a1.y - a2.y)
        let deltaZ = abs(a1.z - a2.z)
        
        return (deltaX <= threshold && deltaY <= threshold && deltaZ <= threshold)
    }
    
    func gaussianFilter(accelerations: [(x: Double, y: Double, z: Double, timestamp: Date)], sigma: Double, period: TimeInterval) -> [(x: Double, y: Double, z: Double, timestamp: Date)] {
        var smoothedAccelerations: [(x: Double, y: Double, z: Double, timestamp: Date)] = []
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
            smoothedAccelerations.append((x: normalizedAcceleration.x, y: normalizedAcceleration.y, z: normalizedAcceleration.z, timestamp: accelerations[i].timestamp))
        }
        
        return smoothedAccelerations
    }
    
    // Function to calculate the change in orientation (Δq)
    func calculateDeltaA(accelerationAtT: (x: Double, y: Double, z: Double), accelerationAtTPlusAlpha: (x: Double, y: Double, z: Double)) -> (x: Double, y: Double, z: Double) {
        // Subtract the acceleration at time t+alpha by the inverse of the acceleration at time t
        return (
            x: accelerationAtTPlusAlpha.x - accelerationAtT.x,
            y: accelerationAtTPlusAlpha.y - accelerationAtT.y,
            z: accelerationAtTPlusAlpha.z - accelerationAtT.z
        )
    }
    
    func synchronizeAccelerations(_ watchAccelerations: [(x: Double, y: Double, z: Double, timestamp: Date)], with iPhoneAccelerations: [(x: Double, y: Double, z: Double, timestamp: Date)]) -> [(watch: (Double, Double, Double), iPhone: (Double, Double, Double))] {
        var alignedPairs: [(watch: (Double, Double, Double), iPhone: (Double, Double, Double))] = []
        
        for watchAcceleration in watchAccelerations {
            // Find the closest iPhone acceleration with the nearest timestamp
            if let closestiPhoneAcceleration = iPhoneAccelerations.min(by: { abs($0.timestamp.timeIntervalSince(watchAcceleration.timestamp)) < abs($1.timestamp.timeIntervalSince(watchAcceleration.timestamp)) }) {
                
                alignedPairs.append((watch: (watchAcceleration.x, watchAcceleration.y, watchAcceleration.z), iPhone: (closestiPhoneAcceleration.x, closestiPhoneAcceleration.y, closestiPhoneAcceleration.z)))
            }
        }
        return alignedPairs
    }
}
