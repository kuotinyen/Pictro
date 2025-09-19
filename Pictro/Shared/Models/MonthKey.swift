//
//  MonthKey.swift
//  Pictro
//
//  Created by Ting-Yen, Kuo on 2025/9/19.
//

import Foundation

struct MonthKey: Hashable, Codable {
    let year: Int
    let month: Int

    var displayString: String {
        return String(format: "%04d/%02d", year, month)
    }

    var localizedDisplayString: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy/MM"
        let date = Calendar.current.date(from: DateComponents(year: year, month: month)) ?? Date()
        return dateFormatter.string(from: date)
    }

    static func == (lhs: MonthKey, rhs: MonthKey) -> Bool {
        return lhs.year == rhs.year && lhs.month == rhs.month
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(year)
        hasher.combine(month)
    }
}

extension MonthKey: Identifiable {
    var id: String {
        return "\(year)-\(month)"
    }
}
