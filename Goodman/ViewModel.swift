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
    @Published var selectedCountryCodes: [String] = ViewModel.defaultSelectedCountryCodes
    private var rateData:ExchangeRateDataList?
    private var lastEditedCountryCode: String = "USA"
    private var lastEditedPrice: String = "100"
    private let rateDataKey = "RateDataKey"
    private let selectedKey = "SelectedCountryCodesKey"
    private let baseKey = "BaseCountryCodeKey"
    private let lastEditedCodeKey = "LastEditedCountryCodeKey"
    private let lastEditedPriceKey = "LastEditedPriceKey"

    private static let defaultSelectedCountryCodes = [
        "USA", "CHN", "JPN", "GBR", "AUS", "CAN", "HKG", "KOR", "BRA"
    ]

    init() {
        loadPersistedState()
    }

    private func loadPersistedState() {
        if let saved = UserDefaults.standard.array(forKey: selectedKey) as? [String], !saved.isEmpty {
            selectedCountryCodes = saved
        }
        if let savedBase = UserDefaults.standard.string(forKey: baseKey), !savedBase.isEmpty {
            baseCountryCode = savedBase
        }
        if let code = UserDefaults.standard.string(forKey: lastEditedCodeKey),
           let price = UserDefaults.standard.string(forKey: lastEditedPriceKey) {
            lastEditedCountryCode = code
            lastEditedPrice = price
        } else {
            lastEditedCountryCode = baseCountryCode
            lastEditedPrice = basePrice
        }
        if let data = UserDefaults.standard.data(forKey: rateDataKey),
           let decoded = try? JSONDecoder().decode(ExchangeRateDataList.self, from: data) {
            rateData = decoded
            if let date = decoded.date {
                updateTime = Self.displayFormatter.string(from: date)
            }
        }
        recalcItems()
    }

    var baseCurrencyName: String {
        baseCountryCode == "CHN" ? "人民币" : "美元"
    }

    var baseCurrencyCode: String {
        baseCountryCode == "CHN" ? "CNY" : "USD"
    }

    var availableToAdd: [ExchangeRateData] {
        guard let list = rateData?.exchangeDataList else { return [] }
        return list
            .filter { !selectedCountryCodes.contains($0.countryCode) }
            .sorted { $0.currencyCode < $1.currencyCode }
    }

    func switchBase(countryCode: String) {
        guard baseCountryCode != countryCode else { return }
        baseCountryCode = countryCode
        lastEditedCountryCode = countryCode
        lastEditedPrice = basePrice
        saveBase()
        saveLastEdited()
        recalcItems()
    }

    func addCurrency(countryCode: String) {
        guard !selectedCountryCodes.contains(countryCode),
              rateData?.exchangeDataList.contains(where: { $0.countryCode == countryCode }) == true else {
            return
        }
        selectedCountryCodes.insert(countryCode, at: 0)
        saveSelected()
        recalcItems()
    }

    func removeCurrency(countryCode: String) {
        guard selectedCountryCodes.count > 1,
              selectedCountryCodes.contains(countryCode) else {
            return
        }
        selectedCountryCodes.removeAll { $0 == countryCode }
        if lastEditedCountryCode == countryCode {
            lastEditedCountryCode = baseCountryCode
            lastEditedPrice = basePrice
            saveLastEdited()
        }
        saveSelected()
        recalcItems()
    }

    func moveCurrency(from source: IndexSet, to destination: Int) {
        selectedCountryCodes.move(fromOffsets: source, toOffset: destination)
        saveSelected()
        recalcItems()
    }

    private func selectedItems(from list: [ExchangeRateData]) -> [ExchangeRateData] {
        selectedCountryCodes.compactMap { code in
            list.first(where: { $0.countryCode == code })
        }
    }

    private func recalcItems() {
        guard let list = rateData?.exchangeDataList,
              let anchor = list.first(where: { $0.countryCode == lastEditedCountryCode }) else {
            return
        }
        let selected = selectedItems(from: list)
        for item in selected {
            if item.countryCode == lastEditedCountryCode {
                item.price = lastEditedPrice
            } else {
                item.price = updatePriceByRate(price: lastEditedPrice, rate: item.exchangeRate, baseRate: anchor.exchangeRate)
            }
            if item.countryCode == baseCountryCode {
                basePrice = item.price
            }
        }
        items = selected
    }

    private static let displayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy/MM/dd"
        return f
    }()

    
    func fetchData() {
        Task {
            let rateData = try await ApiRepository().fetchEurBankHtml()
            DispatchQueue.main.sync {
                guard let fetched = rateData,
                      !fetched.exchangeDataList.isEmpty else {
                    return
                }
                self.rateData = fetched
                self.recalcItems()
                if let date = fetched.date {
                    self.updateTime = Self.displayFormatter.string(from: date)
                }
                self.saveRateData()
            }
        }
    }

    func changeEdit(newPrice:String, countryCode:String) {
        lastEditedCountryCode = countryCode
        lastEditedPrice = newPrice
        saveLastEdited()
        if countryCode == baseCountryCode {
            basePrice = newPrice
        }
        guard let list = rateData?.exchangeDataList,
              let currency = list.first(where: { $0.countryCode == countryCode }) else {
            return
        }
        let selected = selectedItems(from: list)
        for item in selected {
            if item.countryCode == countryCode {
                item.price = newPrice
            } else {
                item.price = updatePriceByRate(price: newPrice, rate: item.exchangeRate, baseRate: currency.exchangeRate)
                if item.countryCode == baseCountryCode {
                    basePrice = item.price
                }
            }
        }
        self.items = selected
    }
    
    func updatePriceByRate(price: String, rate: Double, baseRate: Double) -> String{
        return String(format: "%.2f", ((Double(price) ?? 0.0) * rate/baseRate)).stripTrailingZeros()
    }
    
    private func saveRateData() {
        guard let rateData,
              let encoded = try? JSONEncoder().encode(rateData) else { return }
        UserDefaults.standard.set(encoded, forKey: rateDataKey)
    }

    private func saveSelected() {
        UserDefaults.standard.set(selectedCountryCodes, forKey: selectedKey)
    }

    private func saveBase() {
        UserDefaults.standard.set(baseCountryCode, forKey: baseKey)
    }

    private func saveLastEdited() {
        UserDefaults.standard.set(lastEditedCountryCode, forKey: lastEditedCodeKey)
        UserDefaults.standard.set(lastEditedPrice, forKey: lastEditedPriceKey)
    }
}
