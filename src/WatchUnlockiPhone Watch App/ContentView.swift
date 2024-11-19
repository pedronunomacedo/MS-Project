import SwiftUI
import WatchConnectivity
import Charts

struct ContentView: View {
    @ObservedObject var extensionDelegate = ExtensionDelegate.shared // Observing the shared instance
    
    var accelerometer = Accelerometer.shared
    var quaternions = Quaternions.shared
    @State private var showAlert = false
    @State private var messageInput: String = ""
        
    var body: some View {
        TabView{
            VStack {
                Text("Device Info") // Title for the first screen
                    .font(.headline)
                    .bold()
                    .foregroundColor(.blue)
                Text(extensionDelegate.iPhoneName)
                Button("Send coordinates") {
                    extensionDelegate.sendMessage(content: ["coordinates": accelerometer.coordinates])
                }
            }
            .tabItem {
                Image(systemName: "person.fill")
                Text("Info")
            }
            .ignoresSafeArea()
            
            
            
            VStack(spacing: 0) {
                VStack {
                    HStack {
                        Text("Unlocks") // Title for the second screen
                            .font(.headline)
                            .bold()
                            .foregroundColor(.blue)
                        Spacer() // Pushes the title to the left
                    }
                    .padding(.top, 0) // Add some top padding
                    .frame(maxWidth: .infinity) // Ensure it takes the full width
                    
                    Spacer() // Adds spacing below the title
                    
                    LineChart(data: chartData)
                }
                .frame(maxHeight: .infinity)
            }
            .tabItem {
                Image(systemName: "lock.fill")
                Text("Unlocks")
            }
            
            
            
            VStack {
                Text("Page 3") // Title for the third screen
                    .font(.title3)
                    .bold()
                    .foregroundColor(.blue)
                    .padding(.top, 10)
                Text("Content") // Any additional content for Page 3
            }
            .tabItem {
                Image(systemName: "list.bullet")
                Text("Page 3")
            }
        }
        .tabViewStyle(.carousel)
        .padding(.horizontal, 10)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 25/255, green: 50/255, blue: 80/255),  // Darker blue (bottom)
                    Color(red: 20/255, green: 40/255, blue: 60/255),  // Middle blue 1
                    Color(red: 15/255, green: 30/255, blue: 40/255),  // Middle blue 2
                    Color(red: 10/255, green: 20/255, blue: 25/255),  // Middle blue 3
                    Color(red: 5/255, green: 10/255, blue: 10/255),   // Middle blue 4
                    Color(red: 0/255, green: 0/255, blue: 0/255)      // Complete dark (top)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .onAppear {
            showAlert = !accelerometer.isAccelerometerAvailable
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("Error"),
                message: Text("Accelerometer not available on this device."),
                dismissButton: .default(Text("OK"))
            )
        }
        .overlay(
            Group {
                if extensionDelegate.showUnlockNotification {
                    UnlockNotificationView()
                        .transition(.opacity)
                        .onAppear {
                            withAnimation(.easeInOut(duration: 0.5)) {
                                // Trigger the animation with withAnimation
                            }
                        }
                }
            }
        )
    }
}
