//
//  LocaleUtils.swift
//
//

import Foundation

extension Locale {

    static var deviceLanguage: String {
        return Locale.current.identifier.replacingOccurrences(of: "_", with: "-")
    }

    static var deviceLanguageBackup: String {
        return String(deviceLanguage[deviceLanguage.startIndex ..< deviceLanguage.index(deviceLanguage.startIndex, offsetBy: 2)])
    }

}
