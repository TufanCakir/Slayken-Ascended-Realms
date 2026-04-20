//
//  SupportView.swift
//  Slayken Ascended Realms
//
//  Created by Tufan Cakir on 10.04.26.
//

import SwiftUI

struct SupportView: View {

    @EnvironmentObject var theme: ThemeManager

    @State private var message: String = ""
    @State private var email: String = ""
    @State private var showAlert = false

    var body: some View {

        VStack(spacing: 20) {

            // 🔹 HEADER
            VStack(spacing: 8) {
                Image(systemName: "questionmark.circle.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(.blue)

                Text("Support")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)

                Text("Probleme oder Feedback?\nSchreib uns direkt!")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 40)

            // 🔹 FORM CARD
            VStack(spacing: 14) {

                // EMAIL FIELD
                VStack(alignment: .leading, spacing: 4) {
                    Text("Email")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white.opacity(0.6))

                    TextField("support@tufancakir.com", text: $email)
                        .padding(10)
                        .background(.black)
                        .overlay {
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.white.opacity(0.2))
                        }
                        .foregroundStyle(.white)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                }

                // MESSAGE FIELD
                VStack(alignment: .leading, spacing: 4) {
                    Text("Nachricht")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white.opacity(0.6))

                    TextEditor(text: $message)
                        .frame(height: 120)
                        .padding(8)
                        .background(Color.black.opacity(0.4))
                        .overlay {
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.white.opacity(0.2))
                        }
                        .foregroundStyle(.white)
                }

                // BUTTON
                Button(action: sendSupportMail) {
                    Text("Nachricht senden")
                        .font(.system(size: 15, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            LinearGradient(
                                colors: [Color.blue, Color.purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            in: Capsule()
                        )
                        .foregroundStyle(.white)
                        .shadow(color: .blue.opacity(0.6), radius: 8)
                }
                .padding(.top, 6)
            }
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial.opacity(0.6))
            )
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.2))
            }
            .padding(.horizontal, 20)

            Spacer()

            // 🔹 FOOTER
            VStack(spacing: 4) {
                Text("Oder direkt per Email:")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white.opacity(0.6))

                Text("support@tufancakir.com")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white)
            }
            .padding(.bottom, 20)
        }
        .alert("Gesendet", isPresented: $showAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Deine Nachricht wurde vorbereitet.")
        }
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

    private func sendSupportMail() {
        let subject = "Support Anfrage"
        let body = "Email: \(email)\n\nNachricht:\n\(message)"

        let encodedSubject =
            subject.addingPercentEncoding(
                withAllowedCharacters: .urlQueryAllowed
            ) ?? ""
        let encodedBody =
            body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
            ?? ""

        if let url = URL(
            string:
                "mailto:support@tufancakir.com?subject=\(encodedSubject)&body=\(encodedBody)"
        ) {
            UIApplication.shared.open(url)
            showAlert = true
        }
    }
}

#Preview {
    SupportView()
        .environmentObject(ThemeManager())
}
