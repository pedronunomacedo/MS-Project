import SwiftUI
import WatchKit

struct UnlockNotificationView: View {
    var body: some View {
        VStack {
            Image(systemName: "checkmark.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 50, height: 50)
                .foregroundColor(.green)
            Text("iPhone unlocked")
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.top, 5)
        }
        .background(Color.black.opacity(0.8))
        .shadow(radius: 10)
        .onAppear {
            // Trigger a haptic feedback notification
            WKInterfaceDevice.current().play(.notification)
        }
        .ignoresSafeArea()
    }
}
