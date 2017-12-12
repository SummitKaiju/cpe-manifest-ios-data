//
//  StringUtils.swift
//

import Foundation

extension String {

    func stringByAddingPercentEncodingForURLQueryValue() -> String? {
        let allowedCharacters = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~")
        return self.addingPercentEncoding(withAllowedCharacters: allowedCharacters)
    }

    func iso8601TimeInSeconds() -> TimeInterval {
        if self.count > 2 && self[0] == "P" && self[1] == "T" {
            var currentNumberString = ""
            var hours = 0.0, minutes = 0.0, seconds = 0.0

            
            let timeString = String(self[self.index(self.startIndex, offsetBy: 2)...])
            for i in 0 ..< timeString.count {
                if timeString[i] == "H", let numValue = Double(currentNumberString) {
                    hours = numValue
                    currentNumberString = ""
                } else if timeString[i] == "M", let numValue = Double(currentNumberString) {
                    minutes = numValue
                    currentNumberString = ""
                } else if timeString[i] == "S", let numValue = Double(currentNumberString) {
                    seconds = numValue
                    currentNumberString = ""
                } else {
                    currentNumberString += timeString[i]
                }
            }

            return TimeInterval((hours * 3600) + (minutes * 60) + seconds)
        }

        return 0
    }

    func trim() -> String? {
        return self.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    subscript (i: Int) -> Character {
        return self[self.index(self.startIndex, offsetBy: i)]
    }

    subscript (i: Int) -> String {
        return String(self[i] as Character)
    }

    subscript (r: Range<Int>) -> String {
        let start = self.index(startIndex, offsetBy: r.lowerBound)
        let end = index(start, offsetBy: r.upperBound - r.lowerBound)
        return String(self[start ..< end])
    }

}
