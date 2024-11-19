import SwiftUI

struct UnlockNotificationView: View {
    var body: some View {
        VStack {
            Image(systemName: "lock.open.fill")
                .resizable()
                .frame(width: 50, height: 50)
                .foregroundColor(.green)
            Text("iPhone Unlocked")
                .font(.headline)
                .foregroundColor(.white)
        }
        .padding()
        .background(Color.black.opacity(0.8))
        .cornerRadius(10)
        .shadow(radius: 5)
    }
}

