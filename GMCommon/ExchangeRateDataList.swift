//
//  ExchangeRateDateList.swift
//  GMCommon
//
//  Created by Wooi on 2024/1/16.
//

import Foundation

struct ExchangeRateDataList: Codable {
    let date:Date?
    let baseCurrencyCode: String 
    let baseCurrencyName: String
    var exchangeDataList: [ExchangeRateData] = []
    
    init(date: Date? = nil, baseCurrencyCode: String = "", baseCurrencyName: String = "") {
        self.date = date
        self.baseCurrencyCode = baseCurrencyCode
        self.baseCurrencyName = baseCurrencyName
    }
    
    
}
