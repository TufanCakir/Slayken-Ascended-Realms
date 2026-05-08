//
//  EventDateSupport.swift
//  Slayken Ascended Realms
//
//  Created by Tufan Cakir on 10.04.26.
//

import Foundation

enum EventDateSupport {
    private static let germanTimeZone =
        TimeZone(identifier: "Europe/Berlin") ?? .current
    private static let locale = Locale(identifier: "de_DE_POSIX")
    private static let dateTimeFormats = ["d.M.yyyy HH:mm", "dd.MM.yyyy HH:mm"]
    private static let dateOnlyFormats = ["d.M.yyyy", "dd.MM.yyyy"]

    static func isActive(endsAt: String?, now: Date = .now) -> Bool {
        guard
            let endsAt,
            !endsAt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
            return true
        }

        guard let endDate = parseEndDate(from: endsAt) else {
            return true
        }

        return now <= endDate
    }

    static func displayText(endsAt: String?, now: Date = .now) -> String? {
        guard let endDate = resolvedEndDate(from: endsAt) else { return nil }

        return
            "Endet \(displayFormatter.string(from: endDate)) - \(countdownText(until: endDate, now: now))"
    }

    static func parseEndDate(from text: String) -> Date? {
        for format in dateTimeFormats {
            if let date = formatter(for: format).date(from: text) {
                return date
            }
        }

        for format in dateOnlyFormats {
            if let date = formatter(for: format).date(from: text),
                let endOfDay = Calendar(identifier: .gregorian).date(
                    bySettingHour: 23,
                    minute: 59,
                    second: 59,
                    of: date
                )
            {
                return endOfDay
            }
        }

        return nil
    }

    private static func resolvedEndDate(from text: String?) -> Date? {
        guard
            let text,
            !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
            return nil
        }

        return parseEndDate(from: text)
    }

    private static func countdownText(until endDate: Date, now: Date) -> String
    {
        let remainingSeconds = max(Int(endDate.timeIntervalSince(now)), 0)
        guard remainingSeconds > 0 else { return "beendet" }

        let days = remainingSeconds / 86_400
        let hours = (remainingSeconds % 86_400) / 3_600
        let minutes = (remainingSeconds % 3_600) / 60

        if days > 0 {
            return "noch \(days)d \(hours)h"
        }

        if hours > 0 {
            return "noch \(hours)h \(minutes)m"
        }

        if minutes > 0 {
            return "noch \(minutes)m"
        }

        return "endet gleich"
    }

    private static var displayFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.timeZone = germanTimeZone
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = "dd.MM.yyyy HH:mm"
        return formatter
    }

    private static func formatter(for format: String) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.timeZone = germanTimeZone
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = format
        return formatter
    }
}
