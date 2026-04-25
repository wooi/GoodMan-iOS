//
//  Test.swift
//  Common
//
//  Created by Wooi on 2024/1/6.
//

import Foundation
import Alamofire
import SwiftSoup

class ApiRepository {

    func fetchData() async throws -> ExchangeRateApiData? {
        let key = Constant.API_KEY
        let url = URL(string: "https://v6.exchangerate-api.com/v6/\(key)/pair/USD/CNY")
        let dataTask = AF.request(url!, method: .get)
            .serializingDecodable(ExchangeRateApiData.self)
        let result = await dataTask.result
        switch result {
        case .success(let exchangeRateData):
            return exchangeRateData
        case .failure(let error):
            print("Error: \(error)")
            return nil
        }
    }

    func fetchEurBankHtml() async throws -> ExchangeRateDataList? {
        let url = URL(string: "https://www.ecb.europa.eu/stats/policy_and_exchange_rates/euro_reference_exchange_rates/html/index.en.html")
        let dataTask = AF.request(url!, method: .get)
            .serializingString()
        let result = await dataTask.result
        switch result {
        case .success(let exchangeRateData):
            let exchangeRateDataList = parseHTML(htmlString: exchangeRateData)
            return exchangeRateDataList
        case .failure(let error):
            print("Error: \(error)")
            return nil
        }

    }

    func parseHTML(htmlString: String) -> ExchangeRateDataList? {
        let numberSet: Set<String> = ["CNY","AUD","EUR","HKD","JPY","BRL","CAD","KRW","GBP", "USD"]

        do {
            let doc = try SwiftSoup.parse(htmlString)
            let date = try doc.select("h3").first()?.text()

            // 通过标签和类名选择元素
            let tboby = try doc.select("tbody")

            var list = ExchangeRateDataList(date: date?.toDate(), baseCurrencyCode: CurrencyCode.EUR, baseCurrencyName: "")
            let currencyElements = try tboby.select("tr")

            for currencyElement in currencyElements {
                // 提取货币代码
                let rateData = ExchangeRateData(date: date?.toDate())
                
                if let currencyCode = try? currencyElement.select(".currency a").text() {
//                    print(currencyCode)
                    if(!numberSet.contains(currencyCode)) {
                        continue
                    }
                    rateData.currencyCode = currencyCode
                    rateData.countryCode = CountryConstant().getAlpha3Code(forCurrencyCode: currencyCode) ?? ""
                }

                if let currencyName = try? currencyElement.select(".alignLeft a").text() {
                    rateData.currencyName = currencyName
                }

                if let exchangeRate = try? currencyElement.select(".spot .rate").text() {
                    rateData.exchangeRate = Double(exchangeRate) ?? 0
                }

                if let trend = try? currencyElement.select(".spot .trend").text() {
                    rateData.trend = trend
                }
                list.exchangeDataList.append(rateData)
            }
            for item in list.exchangeDataList {
                print(item.countryCode)
                print(item.exchangeRate)
            }
            return list
        } catch {
            print("Error parsing HTML: \(error.localizedDescription)")
        }
        return nil
    }
}

