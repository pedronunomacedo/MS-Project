import SwiftUI

struct ContentView: View {
    @ObservedObject var sessionManager = iPhoneSessionManager.shared   // Observing watch data
    @ObservedObject var motionProcessor = MotionDataProcessor.shared   // Observing motion data processor
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Text("Device Motion Data")
                        .font(.largeTitle)
                        .bold()
                        .foregroundColor(.blue)
                        .padding()

                    // iPhone Data
                    Group {
                        VStack {
                            Text("Number of unlocks")
                                .font(.title2)
                                .bold()
                                .foregroundColor(.green)
                            
                            Text("\(self.motionProcessor.numberUnlocks)")
                        }
                        
                    }

                    Divider()

                    // Watch Data
                    Group {
                        VStack {
                            Text("Number of unlocks")
                                .font(.title2)
                                .bold()
                                .foregroundColor(.green)
                            
                            Text("\(self.motionProcessor.numberUnlocks)")
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Motion Data")
        }
    }
}
