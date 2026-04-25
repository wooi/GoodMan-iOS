//
//  CountryConstant.swift
//  GMCommon
//
//  Created by Wooi on 2024/1/15.
//

import Foundation


struct CountryConstant {
    let currencyToAlpha3Mapping: [String: String] = [
        "USD": "USA",
        "JPY": "JPN",
        "BGN": "BGR",
        "CZK": "CZE",
        "DKK": "DNK",
        "GBP": "GBR",
        "HUF": "HUN",
        "PLN": "POL",
        "RON": "ROU",
        "SEK": "SWE",
        "CHF": "CHE",
        "ISK": "ISL",
        "NOK": "NOR",
        "TRY": "TUR",
        "AUD": "AUS",
        "BRL": "BRA",
        "CAD": "CAN",
        "CNY": "CHN",
        "HKD": "HKG",
        "IDR": "IDN",
        "ILS": "ISR",
        "INR": "IND",
        "KRW": "KOR",
        "MXN": "MEX",
        "MYR": "MYS",
        "NZD": "NZL",
        "PHP": "PHL",
        "SGD": "SGP",
        "THB": "THA",
        "ZAR": "ZAF"
    ]

    // 根据货币码获取 Alpha-3 code
    func getAlpha3Code(forCurrencyCode currencyCode: String) -> String? {
        return currencyToAlpha3Mapping[currencyCode]
    }

    // 根据 Alpha-3 code 获取货币码
    func getCurrencyCode(forAlpha3Code alpha3Code: String) -> String? {
        for (currency, code) in currencyToAlpha3Mapping {
            if code == alpha3Code {
                return currency
            }
        }
        return nil
    }
//    // 测试
//    if let usCurrencyCode = getCurrencyCode(forCountryCode: "US") {
//        print("Currency code for US: \(usCurrencyCode)")  // 输出: Currency code for US: USD
//    }
//
//    if let indiaCountryCode = getCountryCode(forCurrencyCode: "INR") {
//        print("Country code for INR: \(indiaCountryCode)")  // 输出: Country code for INR: IN
//    }
    
}

