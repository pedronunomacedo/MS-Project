import SwiftUI
import Charts

struct ContentView: View {
    @StateObject var motionService = MotionDataService() // Observing the motion data service
    
    var body: some View {
        TabView {
            // First Tab: Display Latest Acceleration and Quaternion
            VStack(spacing: 20) {
                Text("Device Info") // Title for the screen
                    .font(.headline)
                    .bold()
                    .foregroundColor(.blue)
                
                // Display Latest Acceleration
                if let acceleration = motionService.accelerationBuffer.last {
                    VStack {
                        Text("Latest Acceleration:")
                            .font(.subheadline)
                            .bold()
                            .foregroundColor(.gray)
                        Text("X: \(String(format: "%.2f", acceleration.x))")
                        Text("Y: \(String(format: "%.2f", acceleration.y))")
                        Text("Z: \(String(format: "%.2f", acceleration.z))")
                    }
                } else {
                    Text("No Acceleration Data")
                        .foregroundColor(.red)
                }
                
                // Display Latest Quaternion
                if let quaternion = motionService.quaternionBuffer.last {
                    VStack {
                        Text("Latest Quaternion:")
                            .font(.subheadline)
                            .bold()
                            .foregroundColor(.gray)
                        Text("W: \(String(format: "%.2f", quaternion.w))")
                        Text("X: \(String(format: "%.2f", quaternion.x))")
                        Text("Y: \(String(format: "%.2f", quaternion.y))")
                        Text("Z: \(String(format: "%.2f", quaternion.z))")
                    }
                } else {
                    Text("No Quaternion Data")
                        .foregroundColor(.red)
                }
            }
            .tabItem {
                Image(systemName: "person.fill")
                Text("Info")
            }
        }
        .ignoresSafeArea()
    }
}
