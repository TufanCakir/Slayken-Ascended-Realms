//
//  StoryView.swift
//  Slayken Ascended Realms
//
//  Created by Tufan Cakir on 10.04.26.
//

import SwiftUI

struct StoryView: View {

    @EnvironmentObject var theme: ThemeManager

    let story: [StoryLine]
    let onFinish: () -> Void

    @State private var currentIndex = 0

    var body: some View {
        ZStack {

            // 🔥 DARK BACKGROUND
            Color.black.opacity(0.6)
                .ignoresSafeArea()

            // 💬 CENTER DIALOG
            VStack(spacing: 16) {

                Text(story[currentIndex].speaker)
                    .font(.headline)
                    .foregroundStyle(.white)

                Text(story[currentIndex].text)
                    .font(.body)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                Button {
                    next()
                } label: {
                    Text("Weiter")
                        .font(.headline)
                        .foregroundStyle(.white).padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .foregroundStyle(.white)
                        .background {
                            LinearGradient(
                                colors: [
                                    theme.selectedTheme?.primary.color
                                        ?? .blue,
                                    theme.selectedTheme?.secondary.color
                                        ?? .cyan,
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        }
                        .clipShape(Capsule())
                }
            }
            .padding()
            .padding(.horizontal)
            .background(
                LinearGradient(
                    colors: [
                        theme.selectedTheme?.accent.color ?? .black,
                        (theme.selectedTheme?.accent.color ?? .black).opacity(
                            0.7
                        ),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )

            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay {
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        theme.selectedTheme?.primary.color ?? .blue,
                        lineWidth: 2
                    )
            }
        }
        .onTapGesture {
            next()
        }
    }

    func next() {
        if currentIndex < story.count - 1 {
            currentIndex += 1
        } else {
            onFinish()
        }
    }
}

#Preview {
    StoryView(
        story: previewStoryLines,
        onFinish: {}
    )
    .environmentObject(ThemeManager())
}

private let previewStoryLines: [StoryLine] = [
    #"{"speaker":"Erza","text":"Die Schatten bewegen sich wieder."}"#,
    #"{"speaker":"Slayken","text":"Dann betreten wir das Reich und beenden es."}"#,
]
.compactMap { line in
    try? JSONDecoder().decode(StoryLine.self, from: Data(line.utf8))
}
