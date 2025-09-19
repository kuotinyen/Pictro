//
//  Date+Extensions.swift
//  Pictro
//
//  Created by Ting-Yen, Kuo on 2025/9/19.
//

import Foundation

extension Date {
    func ISO8601String() -> String {
        let formatter = ISO8601DateFormatter()
        return formatter.string(from: self)
    }
}
