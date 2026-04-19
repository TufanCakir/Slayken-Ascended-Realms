//
//  NewsView.swift
//  Slayken Ascended Realms
//

import SwiftUI

struct NewsView: View {
    private let activities: [NewsItem] = [
        NewsItem(
            title: "Realm Route aktiv",
            subtitle: "Neue Battle-Nodes werden Schritt fuer Schritt auf der World Map freigeschaltet.",
            systemName: "map.fill",
            tint: Color(red: 0.14, green: 0.48, blue: 0.95)
        ),
        NewsItem(
            title: "Summon Banner",
            subtitle: "Sammle Charaktere und baue dein Team fuer kommende Kaempfe aus.",
            systemName: "sparkles",
            tint: Color(red: 0.78, green: 0.42, blue: 0.96)
        ),
        NewsItem(
            title: "Battle Skills",
            subtitle: "Skill Cards loesen eigene Effekte aus und geben deinem Team mehr Kontrolle im Kampf.",
            systemName: "bolt.fill",
            tint: Color(red: 0.96, green: 0.68, blue: 0.20)
        )
    ]

    private let features: [NewsItem] = [
        NewsItem(
            title: "3D Charaktere",
            subtitle: "Shela und Zaron koennen direkt in der Spielszene angezeigt werden.",
            systemName: "person.crop.square.fill",
            tint: Color(red: 0.22, green: 0.76, blue: 0.72)
        ),
        NewsItem(
            title: "Themes",
            subtitle: "Wechsle Look und Stimmung deiner Realm-Oberflaeche ueber das Schnellmenue.",
            systemName: "paintbrush.fill",
            tint: Color(red: 0.38, green: 0.64, blue: 0.96)
        ),
        NewsItem(
            title: "Support",
            subtitle: "Feedback und Fehlerberichte koennen direkt aus der App vorbereitet werden.",
            systemName: "questionmark.circle.fill",
            tint: Color(red: 0.32, green: 0.82, blue: 0.42)
        )
    ]

    var body: some View {
        ZStack {
            background

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    header

                    newsSection(title: "Aktivitaeten", items: activities)
                    newsSection(title: "Neue Features", items: features)
                }
                .padding(.horizontal, 20)
                .padding(.top, 32)
                .padding(.bottom, 34)
            }
        }
    }

    private var background: some View {
        LinearGradient(
            colors: [
                Color(red: 0.04, green: 0.06, blue: 0.10),
                Color(red: 0.09, green: 0.13, blue: 0.20),
                Color(red: 0.03, green: 0.04, blue: 0.07)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Image(systemName: "newspaper.fill")
                    .font(.system(size: 22, weight: .black))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(Color(red: 0.14, green: 0.48, blue: 0.95), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text("News")
                        .font(.system(size: 30, weight: .black))
                        .foregroundStyle(.white)

                    Text("Aktuelles aus Slayken Ascended Realms")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.66))
                }
            }

            Text("Hier findest du laufende Aktivitaeten, neue Inhalte und wichtige Spiel-Updates.")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white.opacity(0.72))
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 8)
        }
    }

    private func newsSection(title: String, items: [NewsItem]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title.uppercased())
                .font(.system(size: 11, weight: .black))
                .tracking(1.4)
                .foregroundStyle(.white.opacity(0.52))

            VStack(spacing: 10) {
                ForEach(items) { item in
                    newsRow(item)
                }
            }
        }
    }

    private func newsRow(_ item: NewsItem) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: item.systemName)
                .font(.system(size: 17, weight: .black))
                .foregroundStyle(.white)
                .frame(width: 38, height: 38)
                .background(item.tint, in: RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 5) {
                Text(item.title)
                    .font(.system(size: 16, weight: .black))
                    .foregroundStyle(.white)

                Text(item.subtitle)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white.opacity(0.70))
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(.white.opacity(0.12), lineWidth: 1)
        }
    }
}

private struct NewsItem: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let systemName: String
    let tint: Color
}

#Preview {
    NewsView()
}
