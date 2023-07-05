//
//  StringExtenxion.swift
//  Computer
//
//  Created by 金子広樹 on 2023/07/04.
//

import SwiftUI

extension String {
    func numberOfOccurrences(of word: String) -> Int {
        var count = 0
        var nextRange = self.startIndex ..< self.endIndex
        while let range = self.range(of: word, options: .caseInsensitive, range: nextRange) {
            count += 1
            nextRange = range.upperBound ..< self.endIndex
        }
        return count
    }
}
