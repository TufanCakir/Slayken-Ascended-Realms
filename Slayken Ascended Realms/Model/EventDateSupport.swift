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

    private static func formatter(for format: String) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.timeZone = germanTimeZone
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = format
        return formatter
    }
}
