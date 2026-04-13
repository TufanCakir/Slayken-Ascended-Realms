//
//  SupportView.swift
//  Slayken Ascended Realms
//
//  Created by Tufan Cakir on 13.04.26.
//

import SwiftUI

struct SupportView: View {
    @State private var message: String = ""
    @State private var email: String = ""
    @State private var showAlert = false

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {

                Image(systemName: "questionmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.blue)
                    .padding(.top, 20)

                Text("Support")
                    .font(.largeTitle.bold())

                Text("Hast du ein Problem oder Feedback? Schreib mir gerne!")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                VStack(alignment: .leading, spacing: 12) {

                    TextField("support@tufancakir.com", text: $email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)

                    TextEditor(text: $message)
                        .frame(height: 150)
                        .padding(8)
                        .background(
                            RoundedRectangle(cornerRadius: 10).stroke(
                                Color.gray.opacity(0.3)
                            )
                        )
                }
                .padding(.horizontal)

                Button(action: sendSupportMail) {
                    Text("Nachricht senden")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .padding(.horizontal)

                Spacer()

                VStack(spacing: 4) {
                    Text("Oder direkt per Email:")
                        .font(.footnote)
                        .foregroundColor(.gray)

                    Text("support@tufancakir.com")
                        .font(.footnote.bold())
                }
                .padding(.bottom, 20)
            }
            .navigationBarTitleDisplayMode(.inline)
            .alert("Gesendet", isPresented: $showAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Deine Nachricht wurde vorbereitet.")
            }
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
}
