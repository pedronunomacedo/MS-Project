import SwiftUI
import WatchConnectivity

struct UnlockButtonView: View {
    @State private var iPhoneName: String = "No iPhone"
    
    var body: some View {
        VStack {
            Text("Unlock \(self.iPhoneName)")
                .font(.headline)
            
            Button(action: {
                
            }) {
                Text("Tap to Unlock")
                    .font(.system(size: 16, weight: .bold))
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
        .padding()
    }
}
