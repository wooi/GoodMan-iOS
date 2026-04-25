//
//  ExchangeRateData.swift
//  GMCommon
//
//  Created by Wooi on 2024/1/16.
//

import Foundation

class ExchangeRateData : Identifiable, Codable{
    let date:Date?
    var currencyCode: String
    var currencyName: String
    var countryCode: String
    var exchangeRate: Double
    var trend: String
    var price: String
    
    init(date: Date? = nil, currencyCode: String = "", currencyName: String = "",countryCode: String = "", exchangeRate: Double = 0, trend: String = "", price: String = "") {
        self.date = date
        self.currencyCode = currencyCode
        self.currencyName = currencyName
        self.countryCode = countryCode
        self.exchangeRate = exchangeRate
        self.trend = trend
        self.price = price
    }
    
}


