import Foundation
import CoreMotion

class MotionDataProcessor: ObservableObject {
    static let shared = MotionDataProcessor() // Singleton instance
    
    // Buffer limits#imageLiteral(resourceName: "C1612629-3DA5-4BFC-BD30-99C80CB4374B_1_105_c.jpeg")
    private let bufferLimit = 34
    private let overlapCount = 14 // First 14 samples of the next window
    private let movementSamples = 15 // Nr. of samples needed to be in sync in order to consider devices synchronization
    private static var accelerationDiffThreshold = 0.20 // Static threshold for acceleration instances difference
    private static var accelerationStationaryThreshold = 0.10 // Static threshold for stationary accelerations
    private static var turningPointsOverlapThreshold = 0.60 // Static threshold overlap for turning points

    // Buffers for motion data
    @Published var watchAccelerationBuffer: [Acceleration] = [Acceleration]()
    @Published var iPhoneAccelerationBuffer: [Acceleration] = [Acceleration]()
    @Published var watchQuaternionsBuffer: [Quaternion] = [Quaternion]()
    @Published var iPhoneQuaternionsBuffer: [Quaternion] = [Quaternion]()
    private let bufferQueue = DispatchQueue(label: "com.motiondataprocessor.bufferQueue")
    
    @Published var numberUnlocks = 0 // Number of unlocks
    @Published var numberTries = 0 // Number of tries
    
    func addData(source: String, accelerations: [Acceleration], quaternions: [Quaternion]) {
        bufferQueue.async {
            switch source {
            case "watch":
                DispatchQueue.main.async {
                    self.watchAccelerationBuffer.append(contentsOf: accelerations)
                    self.watchQuaternionsBuffer.append(contentsOf: quaternions)
                }
            case "iPhone":
                DispatchQueue.main.async {
                    self.iPhoneAccelerationBuffer.append(contentsOf: accelerations)
                    self.iPhoneQuaternionsBuffer.append(contentsOf: quaternions)
                }
            default:
                print("Invalid source: \(source)")
            }

            // Check if buffers are ready for processing
            self.manageBufferSize()
        }
    }

    // Check if the buffer is ready for processing
    private func manageBufferSize() {
        bufferQueue.async {
            
            // Ensure that the buffers only have the last 2 windows (maximum size of 40 samples)
            DispatchQueue.main.async {
                if self.watchAccelerationBuffer.count > 40 {
                    self.watchAccelerationBuffer.removeFirst(self.watchAccelerationBuffer.count - 40)
                }
                
                if self.watchQuaternionsBuffer.count > 40 {
                    self.watchQuaternionsBuffer.removeFirst(self.watchQuaternionsBuffer.count - 40)
                }
                
                if self.iPhoneAccelerationBuffer.count > 40 {
                    self.iPhoneAccelerationBuffer.removeFirst(self.iPhoneAccelerationBuffer.count - 40)
                }
                
                if self.iPhoneQuaternionsBuffer.count > 40 {
                    self.iPhoneQuaternionsBuffer.removeFirst(self.iPhoneQuaternionsBuffer.count - 40)
                }
            }
            
            // Process watch acceleration buffer if ready
            if self.watchAccelerationBuffer.count >= self.bufferLimit,
               self.iPhoneAccelerationBuffer.count >= self.bufferLimit
            {
                self.numberTries += 1
                self.processMotionData()
                self.clearBuffers()
            }
        }
    }

    // Clear the buffer after processing
    private func clearBuffers() {
        DispatchQueue.main.async {
            self.watchAccelerationBuffer.removeFirst(self.watchAccelerationBuffer.count >= 20 ? 20 : self.watchAccelerationBuffer.count) // Remove first window
            self.iPhoneAccelerationBuffer.removeFirst(self.iPhoneAccelerationBuffer.count >= 20 ? 20 : self.iPhoneAccelerationBuffer.count) // Remove first window
            self.watchQuaternionsBuffer.removeFirst(self.watchQuaternionsBuffer.count >= 20 ? 20 : self.watchQuaternionsBuffer.count) // Remove first window
            self.iPhoneQuaternionsBuffer.removeFirst(self.iPhoneQuaternionsBuffer.count >= 20 ? 20 : self.iPhoneQuaternionsBuffer.count) // Remove first window
        }
    }
    
    // Process the motion data
    private func processMotionData() {
        let watchAccelerations = self.watchAccelerationBuffer
        let iPhoneAccelerations = self.iPhoneAccelerationBuffer
        let watchQuaternions = self.watchQuaternionsBuffer
        let iPhoneQuaternions = self.iPhoneQuaternionsBuffer
        
        var accelerationsSynched = false
        var quaternionsSynched = false
        
        /// Step 1: Deal with watch accelerations and Phone accelerations
        if self.dealWithAccelerations(watchAccelerations: watchAccelerations, iPhoneAccelerations: iPhoneAccelerations) {
            accelerationsSynched = true
        }
        
        if (!accelerationsSynched) {
            return
        }
        
        /// Step 2: Deal with watch quaternions and iPhone
        if self.dealWithQuaternions(watchQuaternions: watchQuaternions, iPhoneQuaternions: iPhoneQuaternions) {
            quaternionsSynched = true
        }
        
        /// Step 3: If both accelerations and quaternions are synchronized, then the unlock conditions are met
        if (quaternionsSynched) {
            print("Unlocking!")
            DispatchQueue.main.async {
                self.numberUnlocks += 1
            }
        }
    
    }
    
    // Align the quaternions data between different coordinate systems
    private func dealWithQuaternions(watchQuaternions: [Quaternion], iPhoneQuaternions: [Quaternion]) -> Bool{
        print("-------------------------------------------------------------------------------")
        
        guard (!watchQuaternions.isEmpty && !iPhoneQuaternions.isEmpty) else {
            print("No quaternions data to align.")
            return false
        }
        
        /// Step 1: Synchronize watch and iPhone clocks (altough the devices only collect data if both devices are reachable)
        let synchronizedQuaternions = synchronizeQuaternions(watchQuaternions, with: iPhoneQuaternions)
                
        guard synchronizedQuaternions.count >= self.movementSamples else {
            print("Not enough samples for a sliding window analysis.")
            return false
        }
        
        /// Step 2: Align the quaternions watch axis with the quaternions iPhone axis
        let watchQuaternions = synchronizedQuaternions.map { (watch: Quaternion, iPhone: Quaternion) in
            return watch
        }
        
        let iPhoneQuaternions = synchronizedQuaternions.map { (watch: Quaternion, iPhone: Quaternion) in
            return iPhone
        }
        
        print("watchQuaternions: ", watchQuaternions)
        print("iPhoneQuaternions: ", iPhoneQuaternions)
        
        let watchDeltas = zip(watchQuaternions, watchQuaternions.dropFirst()).map { self.calculateDeltaQuaternion(current: $0, next: $1) }
        let phoneDeltas = zip(iPhoneQuaternions, iPhoneQuaternions.dropFirst()).map { self.calculateDeltaQuaternion(current: $0, next: $1) }
        
        print("watchDeltas: ", watchDeltas)
        print("phoneDeltas: ", phoneDeltas)
        
        /// Step 3: Estimate basis transofrmation between the two devices quaternions axis
        guard let basisR = self.estimateBasisTransformation(watchDeltas: watchDeltas, phoneDeltas: phoneDeltas) else {
            return false
        }
        
        print("basisR: ", basisR)
        
        /// Step 4: Align the iPhone quaternions with the watch quaternions
        let alignedQuaternions = self.alignQuaternions(watchQuaternions: watchQuaternions, phoneQuaternions: iPhoneQuaternions, basisR: basisR)
        
        print("iPhoneAlignedQuaternions: ", alignedQuaternions)
        print("watchQuaternions: ", watchQuaternions)
        
        /// Step 5: Find important turning points on the quaternions list
        let watchTurningPoints = self.findTurningPoints(data: watchQuaternions)
        let phoneTurningPoints = self.findTurningPoints(data: alignedQuaternions)
        
        print("Watch Turning Points: \(watchTurningPoints)")
        print("iPhone Turning Points: \(phoneTurningPoints)")
        
        /// Step 6: Check for sufficient overlap between turning points
        let sufficientOverlap = self.detectOverlap(watchTurningPoints: watchTurningPoints, phoneTurningPoints: phoneTurningPoints)
        
        if sufficientOverlap {
            print("Turning points overlap detected with sufficient ratio.")
            print("-------------------------------------------------------------------------------")
            return true
        }
        
        print("Insufficient turning point overlap.")
        print("-------------------------------------------------------------------------------")
        return false
    }
    
    // Align the accelerations data between different coordinate systems
    private func dealWithAccelerations(watchAccelerations: [Acceleration], iPhoneAccelerations: [Acceleration]) -> Bool{
        guard (!watchAccelerations.isEmpty && !iPhoneAccelerations.isEmpty) else {
            print("No quaternions data to align.")
            return false
        }
        
        /// Step 1: Synchronize watch and iPhone clocks (altough the devices only collect data if both devices are reachable)
        let synchronizedAccelerations = synchronizeAccelerations(watchAccelerations, with: iPhoneAccelerations)
        
        print("synchronize accelerations: ", synchronizedAccelerations)
        
        guard synchronizedAccelerations.count >= self.movementSamples else {
            print("Not enough samples for a sliding window analysis.")
            return false
        }
        
        /// Step 2: Check if devices are stationary
        if self.areDevicesStationary(synchronizedAccelerations: synchronizedAccelerations) {
            print("Devices are stationary. Not counting as an unlock.")
            return false
        }
        
        /// Step 3: Compare the accelerations between the watch and the iPhone by calculating the magnitude of each acceleration, using a sliding window
        for startIndex in 0...(synchronizedAccelerations.count - self.movementSamples) {
            let window = Array(synchronizedAccelerations[startIndex..<(startIndex + self.movementSamples)])
            
            if self.analyzeWindow(window: window, startIndex: startIndex) {
                print("Window starting at index \(startIndex): The movement matches.")
                return true
            }
        }
        
        return false // No match found
    }

    // Align the acceleration data between different coordinate systems
    func alignQuaternions(watchQuaternions: [Quaternion], phoneQuaternions: [Quaternion], basisR: Quaternion) -> [Quaternion] {
        guard watchQuaternions.count == phoneQuaternions.count else { return [] }
        
        var alignedQuaternions: [Quaternion] = []
        
        for i in 0..<(watchQuaternions.count - 1) {
            let deltaWatch = self.calculateDeltaQuaternion(current: watchQuaternions[i], next: watchQuaternions[i + 1])
            let deltaPhone = self.calculateDeltaQuaternion(current: phoneQuaternions[i], next: phoneQuaternions[i + 1])
            
            // Align watch quaternion with phone quaternion using basis transformation
            let alignedQuaternion = self.applyBasisTransformation(deltaB: deltaPhone, r: basisR)
            alignedQuaternions.append(alignedQuaternion)
        }
        
        return alignedQuaternions
    }
    
    // Analyze a single window of samples
    private func analyzeWindow(window: [(watch: Acceleration, iPhone: Acceleration)], startIndex: Int) -> Bool {
        // Check each pair in the window
        for (index, pair) in window.enumerated() {
            let watchMagnitude = pair.watch.magnitude()
            let iPhoneMagnitude = pair.iPhone.magnitude()
            let difference = abs(watchMagnitude - iPhoneMagnitude)
            
            print("Window index \(startIndex + index): Difference = \(difference)")
            
            // If any sample exceeds the threshold, reject the window
            if difference > MotionDataProcessor.accelerationDiffThreshold {
                return false
            }
        }
        
        // If all differences are within the threshold, accept the window
        return true
    }
    
    // Calculate Delta Quaternion
    func calculateDeltaQuaternion(current: Quaternion, next: Quaternion) -> Quaternion {
        guard let inverseCurrent = current.inverse() else { return current }
        return next * inverseCurrent
    }
    
    // Estimate basis transformation quaterion to transform one device's axis into another device's axis
    func estimateBasisTransformation(watchDeltas: [Quaternion], phoneDeltas: [Quaternion]) -> Quaternion? {
        guard watchDeltas.count == phoneDeltas.count else { return Quaternion(w: 1, x: 0, y: 0, z: 0) }

        var sumR = Quaternion(w: 0, x: 0, y: 0, z: 0)
        for i in 0..<watchDeltas.count {
            let r = watchDeltas[i] * phoneDeltas[i].inverse()!
            sumR = sumR + r
        }

        let count = Double(watchDeltas.count)
        
        return Quaternion(w: sumR.w / count, x: sumR.x / count, y: sumR.y / count, z: sumR.z / count).normalized()
    }
    
    func applyBasisTransformation(deltaB: Quaternion, r: Quaternion) -> Quaternion {
        return r * (deltaB * r.inverse()!)
    }
    
    func findTurningPoints(data: [Quaternion]) -> [Int] {
        var turningPoints: [Int] = []
        for i in 1..<(data.count - 1) {
            let prevMagnitude = data[i - 1].magnitude()
            let currentMagnitude = data[i].magnitude()
            let nextMagnitude = data[i + 1].magnitude()

            if (currentMagnitude > prevMagnitude && currentMagnitude > nextMagnitude) ||
               (currentMagnitude < prevMagnitude && currentMagnitude < nextMagnitude) {
                turningPoints.append(i)
            }
        }
        return turningPoints
    }
    
    func detectOverlap(watchTurningPoints: [Int], phoneTurningPoints: [Int]) -> Bool {
        let commonPoints = watchTurningPoints.filter { phoneTurningPoints.contains($0) }
        let overlapRatio = Double(commonPoints.count) / Double(watchTurningPoints.count)
        return overlapRatio >= MotionDataProcessor.turningPointsOverlapThreshold
    }
    
    private func areDevicesStationary(synchronizedAccelerations: [(watch: Acceleration, iPhone: Acceleration)]) -> Bool {
        // Calculate the average magnitude of acceleration for the watch and iPhone
        let watchAvgMagnitude = synchronizedAccelerations.map { $0.watch.magnitude() }.reduce(0, +) / Double(synchronizedAccelerations.count)
        let iPhoneAvgMagnitude = synchronizedAccelerations.map { $0.iPhone.magnitude() }.reduce(0, +) / Double(synchronizedAccelerations.count)

        print("Watch Avg Magnitude: \(watchAvgMagnitude), iPhone Avg Magnitude: \(iPhoneAvgMagnitude)")

        // Check if both devices are stationary
        return watchAvgMagnitude < MotionDataProcessor.accelerationStationaryThreshold || iPhoneAvgMagnitude < MotionDataProcessor.accelerationStationaryThreshold
    }
}
