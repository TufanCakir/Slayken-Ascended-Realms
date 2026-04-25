//
//  DailyLoginView.swift
//  Slayken Ascended Realms
//
//  Created by Tufan Cakir on 10.04.26.
//

import SwiftUI

struct DailyLoginView: View {
    let rewards: [DailyLoginRewardDefinition]
    let currencies: [CurrencyDefinition]
    let availableReward: DailyLoginRewardState?
    let onClaim: () -> Void
    let onClose: () -> Void

    private var highlightedDay: Int {
        availableReward?.dayNumber ?? 1
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.black,
                    Color(red: 0.11, green: 0.08, blue: 0.07),
                    Color(red: 0.24, green: 0.14, blue: 0.12),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 20) {
                header
                statusCard

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 12) {
                        ForEach(rewards) { reward in
                            rewardDayCard(reward)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
                }
            }
            .padding(.top, 20)
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text("Daily Login")
                    .font(.system(size: 30, weight: .black, design: .serif))
                    .foregroundStyle(.white)

                Text("30 Tage Login-Belohnungen")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.7))
            }

            Spacer()

            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .black))
                    .foregroundStyle(.white)
                    .frame(width: 42, height: 42)
                    .background(Color.white.opacity(0.1), in: Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
    }

    private var statusCard: some View {
        VStack(spacing: 14) {
            Text(
                availableReward == nil
                    ? "Heute bereits eingesammelt" : "Belohnung verfuegbar"
            )
            .font(.system(size: 12, weight: .black, design: .rounded))
            .tracking(2)
            .foregroundStyle(.white.opacity(0.72))

            if let availableReward {
                Text(
                    "Tag \(availableReward.dayNumber): \(availableReward.reward.title)"
                )
                .font(.system(size: 20, weight: .bold, design: .serif))
                .multilineTextAlignment(.center)
                .foregroundStyle(.white)

                Button(action: onClaim) {
                    Text(availableReward.reward.buttonTitle)
                        .font(
                            .system(size: 15, weight: .black, design: .rounded)
                        )
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            Color(red: 0.84, green: 0.34, blue: 0.22),
                            in: RoundedRectangle(
                                cornerRadius: 16,
                                style: .continuous
                            )
                        )
                        .foregroundStyle(.white)
                }
                .buttonStyle(.plain)
            } else {
                Text("Komm morgen wieder fuer den naechsten Kalendertag.")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white.opacity(0.84))
            }
        }
        .padding(20)
        .background(
            Color.white.opacity(0.08),
            in: RoundedRectangle(cornerRadius: 24, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
        .padding(.horizontal, 20)
    }

    private func rewardDayCard(_ reward: DailyLoginRewardDefinition)
        -> some View
    {
        let isHighlighted = reward.day == highlightedDay

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Tag \(reward.day)")
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .foregroundStyle(.white)

                Spacer()

                Image(systemName: reward.icon)
                    .foregroundStyle(
                        isHighlighted ? Color.orange : .white.opacity(0.72)
                    )
            }

            Text(reward.title)
                .font(.system(size: 18, weight: .bold, design: .serif))
                .foregroundStyle(.white)

            Text(reward.subtitle)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.72))

            VStack(spacing: 8) {
                ForEach(reward.rewards) { item in
                    HStack {
                        Image(
                            systemName: currencies.first(where: {
                                $0.code == item.currency
                            })?.icon ?? "gift.fill"
                        )
                        .foregroundStyle(Color.orange)
                        .frame(width: 20)

                        Text(
                            currencies.first(where: { $0.code == item.currency }
                            )?.name ?? item.currency.capitalized
                        )
                        .font(
                            .system(size: 14, weight: .bold, design: .rounded)
                        )
                        .foregroundStyle(.white)

                        Spacer()

                        Text("+\(item.amount)")
                            .font(
                                .system(
                                    size: 14,
                                    weight: .black,
                                    design: .rounded
                                )
                            )
                            .foregroundStyle(.white.opacity(0.88))
                    }
                }
            }
        }
        .padding(16)
        .background(
            (isHighlighted
                ? Color.orange.opacity(0.18) : Color.white.opacity(0.07)),
            in: RoundedRectangle(cornerRadius: 20, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(
                    isHighlighted
                        ? Color.orange.opacity(0.45)
                        : Color.white.opacity(0.08),
                    lineWidth: 1
                )
        )
    }
}
