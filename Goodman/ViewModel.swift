//
//  ViewModel.swift
//  Goodman
//
//  Created by Wooi on 2024/1/16.
//

import Foundation

import SwiftUI
import Combine

class ViewModel: ObservableObject {
    @Published var items: [ExchangeRateData] = []
    @Published var basePrice: String = "100"
    @Published var updateTime: String = ""
    @Published var baseCountryCode: String = "USA"
    private var rateData:ExchangeRateDataList?
    private let dataKey = "ExchangeRateDataKey"

    var baseCurrencyName: String {
        baseCountryCode == "CHN" ? "人民币" : "美元"
    }

    var baseCurrencyCode: String {
        baseCountryCode == "CHN" ? "CNY" : "USD"
    }

    func switchBase(countryCode: String) {
        guard baseCountryCode != countryCode else { return }
        baseCountryCode = countryCode
        recalcItems()
    }

    private func recalcItems() {
        guard let list = rateData?.exchangeDataList,
              let baseItem = list.first(where: { $0.countryCode == baseCountryCode }) else {
            return
        }
        for item in list {
            item.price = item.countryCode == baseCountryCode
                ? basePrice
                : updatePriceByRate(price: basePrice, rate: item.exchangeRate, baseRate: baseItem.exchangeRate)
        }
        items = list
    }

    private static let displayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy/MM/dd"
        return f
    }()

    
    func loadSaveData() {
        if let savedData = UserDefaults.standard.data(forKey: dataKey) {
            if let decodedData = try? JSONDecoder().decode([ExchangeRateData].self, from: savedData) {
                items = decodedData
                if let date = decodedData.first?.date {
                    updateTime = Self.displayFormatter.string(from: date)
                }
                return
            }
        }
    }
    
    func fetchData() {
        loadSaveData()
        
        Task {
            let rateData = try await ApiRepository().fetchEurBankHtml()
            DispatchQueue.main.sync {
                self.rateData = rateData ?? nil
                if rateData?.exchangeDataList != nil {
                    self.recalcItems()
                    if let date = rateData?.date {
                        self.updateTime = Self.displayFormatter.string(from: date)
                    }
                    self.saveData()
                } else {
                    self.items = []
                }
            }
        }
    }
    
    func changeEdit(newPrice:String, countryCode:String) {
        if countryCode == baseCountryCode {
            basePrice = newPrice
        }
        guard let list = rateData?.exchangeDataList,
              let currency = list.first(where: { $0.countryCode == countryCode }) else {
            return
        }
        for item in list {
            if item.countryCode == countryCode {
                item.price = newPrice
            } else {
                item.price = updatePriceByRate(price: newPrice, rate: item.exchangeRate, baseRate: currency.exchangeRate)
                if item.countryCode == baseCountryCode {
                    basePrice = item.price
                }
            }
        }
        self.items = list
    }
    
    func updatePriceByRate(price: String, rate: Double, baseRate: Double) -> String{
        return String(format: "%.2f", ((Double(price) ?? 0.0) * rate/baseRate)).stripTrailingZeros()
    }
    
    private func saveData() {
        if let encodedData = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(encodedData, forKey: dataKey)
        }
    }
}
