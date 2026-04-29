//
//  NewsView.swift
//  Slayken Ascended Realms
//
//  Created by Tufan Cakir on 10.04.26.
//

import SwiftUI
import UIKit

struct NewsView: View {
    var onClose: (() -> Void)? = nil

    @EnvironmentObject var theme: ThemeManager
    @State private var selectedCategory = "Allgemein"

    private let items = loadNewsItems()

    private var categories: [String] {
        ["Allgemein", "Events", "Bug Fixes"]
    }

    private var groupedItems: [(String, [NewsItemDefinition])] {
        let filteredItems =
            selectedCategory == "Allgemein"
            ? items
            : items.filter { normalizedCategory(for: $0) == selectedCategory }

        return Dictionary(
            grouping: filteredItems,
            by: { normalizedCategory(for: $0) }
        )
        .map { ($0.key, $0.value.sorted { $0.date > $1.date }) }
        .sorted { $0.0 < $1.0 }
    }

    var body: some View {
        NavigationStack {

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    header
                    categoryBar

                    if items.isEmpty {
                        emptyState
                    } else {
                        ForEach(groupedItems, id: \.0) {
                            category,
                            categoryItems in
                            newsSection(title: category, items: categoryItems)
                        }
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 24)
                .padding(.bottom, 34)
            }
            .toolbar(.hidden, for: .navigationBar)
            .background {
                ZStack {
                    if let theme = theme.selectedTheme {
                        Image(theme.background)
                            .resizable()
                            .scaledToFill()
                    }

                    LinearGradient(
                        colors: [
                            Color.black.opacity(0.2),
                            Color.black.opacity(0.6),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
                .ignoresSafeArea()
            }
        }
    }

    private var background: some View {
        LinearGradient(
            colors: [
                Color(red: 0.04, green: 0.06, blue: 0.10),
                Color(red: 0.09, green: 0.13, blue: 0.20),
                Color(red: 0.03, green: 0.04, blue: 0.07),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            if let onClose {
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .black))
                        .foregroundStyle(.white)
                        .frame(width: 38, height: 38)
                        .background(Color.black.opacity(0.44), in: Circle())
                        .overlay(
                            Circle().stroke(.white.opacity(0.18), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("News schliessen")
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "newspaper")
                .font(.system(size: 34, weight: .black))
            Text("Keine News gefunden")
                .font(.system(size: 15, weight: .black))
        }
        .foregroundStyle(.white.opacity(0.72))
        .frame(maxWidth: .infinity)
        .padding(28)
        .background(
            Color.white.opacity(0.08),
            in: RoundedRectangle(cornerRadius: 8, style: .continuous)
        )
    }

    private var categoryBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(categories, id: \.self) { category in
                    Button {
                        selectedCategory = category
                    } label: {
                        Text(category)
                            .font(.system(size: 12, weight: .black))
                            .foregroundStyle(
                                selectedCategory == category ? .black : .white
                            )
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(
                                selectedCategory == category
                                    ? Color.yellow
                                    : Color.black.opacity(0.32),
                                in: Capsule()
                            )
                            .overlay {
                                Capsule()
                                    .stroke(
                                        .white.opacity(
                                            selectedCategory == category
                                                ? 0 : 0.10
                                        ),
                                        lineWidth: 1
                                    )
                            }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func normalizedCategory(for item: NewsItemDefinition) -> String {
        let rawCategory = item.category.lowercased()
        let title = item.title.lowercased()
        let subtitle = item.subtitle.lowercased()
        let body = item.body.lowercased()
        let tags = item.tags.joined(separator: " ").lowercased()
        let combinedText = "\(rawCategory) \(title) \(subtitle) \(body) \(tags)"

        if combinedText.contains("bug")
            || combinedText.contains("fix")
            || combinedText.contains("balance")
            || combinedText.contains("maintenance")
            || combinedText.contains("system update")
        {
            return "Bug Fixes"
        }

        if combinedText.contains("event")
            || combinedText.contains("festival")
            || combinedText.contains("rift")
            || combinedText.contains("seasonal")
        {
            return "Events"
        }

        return "Allgemein"
    }

    private func newsSection(title: String, items: [NewsItemDefinition])
        -> some View
    {
        VStack(alignment: .leading, spacing: 12) {
            Text(title.uppercased())
                .font(.system(size: 11, weight: .black))
                .tracking(1.4)
                .foregroundStyle(.white.opacity(0.52))

            VStack(spacing: 12) {
                ForEach(items) { item in
                    NavigationLink {
                        NewsDetailView(item: item)
                    } label: {
                        newsRow(item)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func newsRow(_ item: NewsItemDefinition) -> some View {
        HStack(alignment: .top, spacing: 12) {
            newsImage(item.image)
                .frame(width: 92, height: 62)
                .clipShape(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8).stroke(
                        .white.opacity(0.15),
                        lineWidth: 1
                    )
                )

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Text(item.date)
                        .font(.system(size: 9, weight: .black))
                        .foregroundStyle(.white.opacity(0.48))
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .black))
                        .foregroundStyle(.white.opacity(0.38))
                }

                Text(item.title)
                    .font(.system(size: 16, weight: .black))
                    .foregroundStyle(.white)
                    .lineLimit(1)

                Text(item.subtitle)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.70))
                    .lineLimit(2)
            }
        }
        .padding(12)
        .background(
            Color.white.opacity(0.08),
            in: RoundedRectangle(cornerRadius: 8, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(.white.opacity(0.12), lineWidth: 1)
        }
    }

    @ViewBuilder
    private func newsImage(_ imageName: String) -> some View {
        if UIImage(named: imageName) != nil {
            Image(imageName)
                .resizable()
                .scaledToFill()
        } else {
            ZStack {
                LinearGradient(
                    colors: [.blue.opacity(0.8), .black],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                Image(systemName: "newspaper.fill")
                    .font(.system(size: 24, weight: .black))
                    .foregroundStyle(.white.opacity(0.72))
            }
        }
    }
}

private struct NewsDetailView: View {
    let item: NewsItemDefinition

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.black, Color(red: 0.08, green: 0.12, blue: 0.18),
                    Color.black,
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    heroImage

                    VStack(alignment: .leading, spacing: 10) {
                        Text(item.category.uppercased())
                            .font(.system(size: 10, weight: .black))
                            .tracking(1.5)
                            .foregroundStyle(.white.opacity(0.52))

                        Text(item.title)
                            .font(.system(size: 30, weight: .black))
                            .foregroundStyle(.white)
                            .fixedSize(horizontal: false, vertical: true)

                        Text(item.subtitle)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.72))
                            .fixedSize(horizontal: false, vertical: true)

                        tagRow
                            .padding(.top, 2)

                        Text(item.body)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(.white.opacity(0.82))
                            .lineSpacing(5)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.top, 8)
                    }
                    .padding(.horizontal, 18)
                    .padding(.bottom, 34)
                }
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    private var heroImage: some View {
        Group {
            if UIImage(named: item.image) != nil {
                Image(item.image)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    LinearGradient(
                        colors: [.blue.opacity(0.8), .purple.opacity(0.55)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    Image(systemName: "newspaper.fill")
                        .font(.system(size: 54, weight: .black))
                        .foregroundStyle(.white.opacity(0.75))
                }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 240)
        .clipped()
        .overlay(alignment: .bottomLeading) {
            Text(item.date)
                .font(.system(size: 11, weight: .black))
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.black.opacity(0.62), in: Capsule())
                .padding(16)
        }
    }

    private var tagRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 7) {
                ForEach(item.tags, id: \.self) { tag in
                    Text(tag)
                        .font(.system(size: 10, weight: .black))
                        .foregroundStyle(.black.opacity(0.78))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(Color.cyan.opacity(0.88), in: Capsule())
                }
            }
        }
    }
}

#Preview {
    NewsView(onClose: {})
        .environmentObject(ThemeManager())
}
