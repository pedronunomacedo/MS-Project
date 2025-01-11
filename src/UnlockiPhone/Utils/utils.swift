import Foundation

func applyGaussianFilter(quaternions: [Quaternion], targetTimestamps: [TimeInterval], sigma: Double) -> [Quaternion] {
    var filteredQuaternions: [Quaternion] = []
    
    for targetTime in targetTimestamps {
        var sumWeights = 0.0
        var weightedSumW = 0.0
        var weightedSumX = 0.0
        var weightedSumY = 0.0
        var weightedSumZ = 0.0

        for quaternion in quaternions {
            let timeDiff = quaternion.timestamp - targetTime
            let weight = exp(-pow(timeDiff, 2) / (2 * pow(sigma, 2)))

            sumWeights += weight
            weightedSumW += weight * quaternion.w
            weightedSumX += weight * quaternion.x
            weightedSumY += weight * quaternion.y
            weightedSumZ += weight * quaternion.z
        }

        // Normalize the resulting quaternion
        let normFactor = sqrt(pow(weightedSumW, 2) + pow(weightedSumX, 2) + pow(weightedSumY, 2) + pow(weightedSumZ, 2))

        filteredQuaternions.append(Quaternion(
            w: weightedSumW / normFactor,
            x: weightedSumX / normFactor,
            y: weightedSumY / normFactor,
            z: weightedSumZ / normFactor,
            timestamp: targetTime
        ))
    }

    return filteredQuaternions
}

func calculateTimeOffset(watchQuaternions: [Quaternion], phoneQuaternions: [Quaternion]) -> TimeInterval {
    guard let firstWatchTimestamp = watchQuaternions.first?.timestamp,
          let firstPhoneTimestamp = phoneQuaternions.first?.timestamp else {
        fatalError("Timestamps are missing in the quaternion data!")
    }
    
    // Calculate the offset as the difference between the first timestamps
    return firstWatchTimestamp
}

func synchronizeQuaternions(_ watchQuaternions: [Quaternion], with iPhoneQuaternions: [Quaternion]) -> [(watch: Quaternion, iPhone: Quaternion)] {
    var alignedPairs: [(watch: Quaternion, iPhone: Quaternion)] = []
    var iPhoneIndex = 0

    for watchQuaternion in watchQuaternions {
        // Find the closest iPhone quaternion
        while iPhoneIndex < iPhoneQuaternions.count - 1 &&
              abs(iPhoneQuaternions[iPhoneIndex + 1].timestamp - watchQuaternion.timestamp) <
                abs(iPhoneQuaternions[iPhoneIndex].timestamp - watchQuaternion.timestamp) {
            iPhoneIndex += 1
        }

        // Add the aligned pair
        let closestIPhoneQuaternion = iPhoneQuaternions[iPhoneIndex]
        alignedPairs.append((watch: watchQuaternion, iPhone: closestIPhoneQuaternion))
    }

    return alignedPairs
}

func synchronizeAccelerations(_ watchAccelerations: [Acceleration], with iPhoneAccelerations: [Acceleration]) -> [(watch: Acceleration, iPhone: Acceleration)] {
    var alignedPairs: [(watch: Acceleration, iPhone: Acceleration)] = []
    var iPhoneIndex = 0

    for watchAcceleration in watchAccelerations {
        // Find the closest iPhone quaternion
        while iPhoneIndex < iPhoneAccelerations.count - 1 &&
                abs(iPhoneAccelerations[iPhoneIndex + 1].timestamp - watchAcceleration.timestamp) <
                abs(iPhoneAccelerations[iPhoneIndex].timestamp - watchAcceleration.timestamp) {
            iPhoneIndex += 1
        }

        // Add the aligned pair
        let closestiPhoneAcceleration = iPhoneAccelerations[iPhoneIndex]
        alignedPairs.append((watch: watchAcceleration, iPhone: closestiPhoneAcceleration))
    }

    return alignedPairs
}

func alignAxes(watchQuaternions: [Quaternion], iPhoneQuaternions: [Quaternion]) -> [Quaternion] {
    guard let firstWatchQuaternion = watchQuaternions.first,
          let firstiPhoneQuaternion = iPhoneQuaternions.first else {
        return []
    }

    // Calculate the rotation quaternion to align axes
    let rotationQuaternion = calculateAlignmentQuaternion(from: firstWatchQuaternion, to: firstiPhoneQuaternion)

    // Apply the alignment transformation to all watch quaternions
    return watchQuaternions.map { watchQuaternion in
        guard let inverseRotation = rotationQuaternion.inverse() else {
            // Return the quaternion unchanged if inverse fails
            return watchQuaternion
        }
        return ((rotationQuaternion * watchQuaternion) * inverseRotation)
    }
}

func calculateAlignmentQuaternion(from watchQuaternion: Quaternion, to iPhoneQuaternion: Quaternion) -> Quaternion {
    guard let inverseWatchQuaternion = watchQuaternion.inverse() else {
        // Return an identity quaternion if inversion fails
        return Quaternion(w: 1, x: 0, y: 0, z: 0)
    }
    return (iPhoneQuaternion * inverseWatchQuaternion)
}
