import SwiftUI
import Charts

// Define a structure to represent data points
struct DailyUnlocks: Identifiable {
    var id = UUID()
    var day: String
    var unlocks: Int
}

// Example dataset for the chart
let chartData: [DailyUnlocks] = [
    DailyUnlocks(day: "Mon", unlocks: 3),
    DailyUnlocks(day: "Tue", unlocks: 4),
    DailyUnlocks(day: "Wed", unlocks: 2),
    DailyUnlocks(day: "Thu", unlocks: 5),
    DailyUnlocks(day: "Fri", unlocks: 1)
]

struct LineChart: View {
    var data: [DailyUnlocks]
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                Chart(data) { item in
                    // Outer blue circle (larger)
                    PointMark(
                        x: .value("Day", item.day),
                        y: .value("Unlocks", item.unlocks)
                    )
                    .symbol(Circle()) // Points are shown as dots
                    .symbolSize(70)
                    .foregroundStyle(.blue.opacity(0.4)) // Color of the dots
                    .shadow(color: .white, radius: 10) // Create the light/glow effect
                    
                    // Inner black circle (smaller)
                    PointMark(
                        x: .value("Day", item.day),
                        y: .value("Unlocks", item.unlocks)
                    )
                    .symbol(Circle())  // Inner circle size (adjust as needed)
                    .symbolSize(20)
                    .foregroundStyle(.black)   // Inner circle color
                }
                .chartXAxis {
                    AxisMarks(values: data.map { $0.day }) { value in
                        AxisGridLine().foregroundStyle(.clear) // No grid lines
                        AxisValueLabel()
                            .font(.system(size: 12))
                            .foregroundStyle(.white) // Make the labels more visible
                            .offset(y: 5) // Offset the X-Axis labels downwards
                    }
                }
                .chartYAxis(.hidden) // Hide the vertical axis
                .chartPlotStyle { plotArea in
                    plotArea
                        .background(Color.blue.opacity(0.2)) // Apply the blue background only to the plot area
                        .cornerRadius(10) // Optional: round the corners for better aesthetics
                        .padding(.bottom, 10) // Add vertical margin (spacing) to the plot
                }
                .frame(height: geometry.size.height * 0.6)
                .padding(.top, 10) // Add top margin
                .chartYScale(range: .plotDimension(padding: 15))
            }
        }
    }
}
