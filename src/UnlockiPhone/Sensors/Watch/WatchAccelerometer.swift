import Foundation
import WatchConnectivity

class WatchAccelerometer: ObservableObject {
    static let shared = WatchAccelerometer()
    @Published var coordinates: [Acceleration] = [] // Current Apple watch coordinates
    private let coordinateQueue = DispatchQueue(label: "com.example.watchAccelerometer")
    
    func updateCoordinates(coordinatesRec: [Acceleration]) {
        print("Incoming coordinates to update: \(coordinatesRec.count)")
        print("Self coordinates count: \(self.coordinates.count)")
        
        coordinateQueue.async { // Ensure all updates are serialized
            let newCoordinates = coordinatesRec
            var updatedCoordinates = self.coordinates
            updatedCoordinates.append(contentsOf: newCoordinates) // newCoordinates/window will have 100 samples (and updatedCoordinates will have 200 + 100 = 300 samples)
            
            if updatedCoordinates.count > 200 { // Keep only the latest 200 samples
                updatedCoordinates.removeFirst(updatedCoordinates.count - 200) // Remove the first 100 elements (300 - 200) (the last 100 samples will be kept because it's the next sliding window) - this guarantees that the updateCoordinates list only has a maximum of 200 samples (keeps the last 200 samples of the original list)
            }
                        
            DispatchQueue.main.async { // Switch to main thread to update @Published property
                print("[BEFORE] Updating Published coordinates: \(updatedCoordinates.count)")
                self.coordinates = updatedCoordinates
                print("[AFTER] Updating Published coordinates: \(updatedCoordinates.count)")
            }
        }
    }
}
