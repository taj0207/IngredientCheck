//
//  RegulatoryBadgeView.swift
//  IngredientCheck
//
//  Created on 2025-11-05
//

import SwiftUI

/// Badge view for displaying EU regulatory status
struct RegulatoryBadgeView: View {
    let status: RegulatoryStatus
    let compact: Bool

    init(status: RegulatoryStatus, compact: Bool = false) {
        self.status = status
        self.compact = compact
    }

    var body: some View {
        if status.shouldHighlight {
            HStack(spacing: 4) {
                Image(systemName: status.badgeIcon)
                    .font(.system(size: compact ? 12 : 14, weight: .semibold))

                if !compact {
                    Text(status.localizedName)
                        .font(.system(size: 12, weight: .semibold))
                }
            }
            .foregroundColor(.white)
            .padding(.horizontal, compact ? 6 : 10)
            .padding(.vertical, compact ? 4 : 6)
            .background(badgeColor)
            .cornerRadius(compact ? 6 : 8)
        }
    }

    private var badgeColor: Color {
        switch status {
        case .banned:
            return .red
        case .restricted:
            return .orange
        case .underReview:
            return .yellow.opacity(0.8)
        case .approved:
            return .green
        case .notRegulated:
            return .gray
        }
    }
}

/// Detailed regulatory info card
struct RegulatoryInfoCard: View {
    let status: RegulatoryStatus
    let description: String?

    var body: some View {
        if status.shouldHighlight {
            VStack(alignment: .leading, spacing: 12) {
                // Header with icon and title
                HStack {
                    Image(systemName: status.badgeIcon)
                        .font(.title2)
                        .foregroundColor(iconColor)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(status.localizedName)
                            .font(.headline)
                            .foregroundColor(.primary)

                        Text("EU REACH Regulation")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()
                }

                // Regulatory description
                Text(status.euDescription)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                // Additional details if available
                if let description = description, !description.isEmpty {
                    Divider()

                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                // Warning banner for banned/restricted
                if status == .banned || status == .restricted {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.white)
                        Text(status == .banned ? "Do not use in consumer products" : "Check restrictions before use")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(status == .banned ? Color.red : Color.orange)
                    .cornerRadius(8)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(borderColor, lineWidth: 2)
            )
        }
    }

    private var iconColor: Color {
        switch status {
        case .banned: return .red
        case .restricted: return .orange
        case .underReview: return .yellow
        case .approved: return .green
        case .notRegulated: return .gray
        }
    }

    private var borderColor: Color {
        switch status {
        case .banned: return .red.opacity(0.3)
        case .restricted: return .orange.opacity(0.3)
        case .underReview: return .yellow.opacity(0.3)
        case .approved: return .green.opacity(0.3)
        case .notRegulated: return .gray.opacity(0.3)
        }
    }
}

// MARK: - Previews

#Preview("Banned Badge") {
    VStack(spacing: 20) {
        RegulatoryBadgeView(status: .banned)
        RegulatoryBadgeView(status: .banned, compact: true)
    }
    .padding()
}

#Preview("Restricted Badge") {
    VStack(spacing: 20) {
        RegulatoryBadgeView(status: .restricted)
        RegulatoryBadgeView(status: .restricted, compact: true)
    }
    .padding()
}

#Preview("SVHC Badge") {
    VStack(spacing: 20) {
        RegulatoryBadgeView(status: .underReview)
        RegulatoryBadgeView(status: .underReview, compact: true)
    }
    .padding()
}

#Preview("Regulatory Info Cards") {
    ScrollView {
        VStack(spacing: 16) {
            RegulatoryInfoCard(
                status: .banned,
                description: "Completely banned in EU consumer products under REACH regulations"
            )

            RegulatoryInfoCard(
                status: .restricted,
                description: "Restricted under EU REACH Annex XVII - Limited use conditions apply"
            )

            RegulatoryInfoCard(
                status: .underReview,
                description: "SVHC - Substance of Very High Concern on EU Candidate List"
            )
        }
        .padding()
    }
}
