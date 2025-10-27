//
//  Untitled 5.swift
//  Journali
//
//  Created by Raghad Alamoudi on 04/05/1447 AH.
//

import SwiftUI

struct LargeJournalCard: View {
    let entry: JournalEntry
    let titleColor: Color
    let isSelected: Bool
    let onTap: () -> Void
    let onToggleBookmark: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .topTrailing) {
                VStack(alignment: .leading, spacing: 10) {
                    Text(entry.title)
                        .font(.system(size: 26, weight: .semibold, design: .rounded))
                        .foregroundColor(titleColor)
                        .lineLimit(1)

                    Text(longDate(entry.date))
                        .font(.system(size: 13, weight: .regular, design: .rounded))
                        .foregroundColor(.white.opacity(0.65))

                    Text(entry.body)
                        .font(.system(size: 16, weight: .regular, design: .rounded))
                        .foregroundColor(.white.opacity(0.9))
                        .lineLimit(4)
                        .fixedSize(horizontal: false, vertical: true)

                    Spacer(minLength: 6)
                }
                .padding(.all, 22)
                .frame(maxWidth: .infinity, minHeight: 180, alignment: .leading)
                .background(Color(red: 0.06, green: 0.06, blue: 0.07))
                .cornerRadius(20)
                .shadow(color: Color.black.opacity(0.35), radius: isSelected ? 8 : 4, x: 0, y: 2)

                Button(action: {
                    onToggleBookmark()
                }) {
                    Image(systemName: entry.bookmarked ? "bookmark.fill" : "bookmark")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(entry.bookmarked ? titleColor : Color.white.opacity(0.85))
                        .padding(12)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func longDate(_ date: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateStyle = .medium
        fmt.timeStyle = .none
        return fmt.string(from: date)
    }
}

