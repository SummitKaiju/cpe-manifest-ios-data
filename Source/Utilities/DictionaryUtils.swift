//
//  DictionaryUtils.swift
//

import Foundation

extension Dictionary {

    func stringFromHTTPParameters() -> String {
        let parameterArray = self.compactMap { (key, value) -> String? in
            if let percentEscapedKey = (key as? String)?.stringByAddingPercentEncodingForURLQueryValue(), let percentEscapedValue = (value as? String)?.stringByAddingPercentEncodingForURLQueryValue() {
                return "\(percentEscapedKey)=\(percentEscapedValue)"
            }

            return nil
        }

        return parameterArray.joined(separator: "&")
    }

}
