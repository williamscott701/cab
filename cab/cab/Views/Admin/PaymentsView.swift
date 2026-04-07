import SwiftUI

struct PaymentsView: View {

    @State private var stats: BookingStats?
    @State private var isLoading = true
    @State private var errorMessage: String?

    private let teal = Color(red: 0.0, green: 0.73, blue: 0.78)
    private let gradient = LinearGradient(
        colors: [Color(red: 0.0, green: 0.78, blue: 0.75), Color(red: 0.0, green: 0.68, blue: 0.82)],
        startPoint: .leading,
        endPoint: .trailing
    )

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let errorMessage {
                    ContentUnavailableView {
                        Label("Couldn't Load", systemImage: "wifi.slash")
                    } description: {
                        Text(errorMessage)
                    } actions: {
                        Button("Retry") { Task { await load() } }
                            .buttonStyle(.borderedProminent)
                            .buttonBorderShape(.capsule)
                            .controlSize(.small)
                    }
                } else if let stats {
                    ScrollView {
                        VStack(spacing: 20) {
                            revenueCard(stats.currentMonth)
                            statusRow(stats.currentMonth)
                            monthlySection(stats.monthly)
                            allTimeFooter(stats.allTime)
                        }
                        .padding()
                    }
                    .background(Color(.systemGroupedBackground))
                }
            }
            .navigationTitle("Payments")
            .navigationBarTitleDisplayMode(.inline)
            .task { await load() }
            .refreshable { await load() }
        }
    }

    // MARK: - Current Month Revenue Card

    private func revenueCard(_ cm: BookingStats.CurrentMonth) -> some View {
        VStack(spacing: 8) {
            Text(currentMonthName())
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)

            Text("₹\(Int(cm.revenue))")
                .font(.system(size: 44, weight: .bold, design: .rounded))
                .foregroundStyle(teal)

            Text("\(cm.completed) completed booking\(cm.completed == 1 ? "" : "s")")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(.regularMaterial, in: .rect(cornerRadius: 16))
    }

    // MARK: - Status Counts Row

    private func statusRow(_ cm: BookingStats.CurrentMonth) -> some View {
        HStack(spacing: 12) {
            statusPill("Pending", count: cm.pending, color: .orange)
            statusPill("Confirmed", count: cm.confirmed, color: .blue)
            statusPill("Cancelled", count: cm.cancelled, color: .secondary)
        }
    }

    private func statusPill(_ label: String, count: Int, color: Color) -> some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(.title3.weight(.bold).monospacedDigit())
                .foregroundStyle(color)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(color.opacity(0.08), in: .rect(cornerRadius: 12))
    }

    // MARK: - Monthly Breakdown

    private func monthlySection(_ months: [BookingStats.MonthEntry]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Monthly Breakdown")
                .font(.headline)
                .padding(.top, 4)

            if months.isEmpty {
                Text("No completed bookings yet.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(months.enumerated()), id: \.element.id) { index, entry in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(entry.displayMonth)
                                    .font(.subheadline.weight(.medium))
                                Text("\(entry.count) booking\(entry.count == 1 ? "" : "s")")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Text("₹\(Int(entry.revenue))")
                                .font(.subheadline.weight(.semibold).monospacedDigit())
                                .foregroundStyle(teal)
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)

                        if index < months.count - 1 {
                            Divider().padding(.leading, 16)
                        }
                    }
                }
                .background(.regularMaterial, in: .rect(cornerRadius: 12))
            }
        }
    }

    // MARK: - All-Time Footer

    private func allTimeFooter(_ allTime: BookingStats.AllTime) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("All-Time Revenue")
                    .font(.subheadline.weight(.medium))
                Text("\(allTime.count) completed booking\(allTime.count == 1 ? "" : "s")")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text("₹\(Int(allTime.revenue))")
                .font(.title3.weight(.bold).monospacedDigit())
                .foregroundStyle(teal)
        }
        .padding(16)
        .background(.regularMaterial, in: .rect(cornerRadius: 12))
    }

    // MARK: - Helpers

    private func currentMonthName() -> String {
        let f = DateFormatter()
        f.dateFormat = "MMMM yyyy"
        return f.string(from: Date())
    }

    private func load() async {
        if stats == nil { isLoading = true }
        errorMessage = nil
        defer { isLoading = false }
        do {
            stats = try await APIClient.shared.perform("/api/bookings/stats")
        } catch is CancellationError {
            // View disappeared — ignore silently
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    PaymentsView()
        .environment(AuthManager())
}
