//
//  ExchangeRateData.swift
//  Goodman
//
//  Created by Wooi on 2024/1/6.
//


struct ExchangeRateApiData: Decodable {
    let result: String
    let documentation: String
    let terms_of_use: String
    let time_last_update_unix: Int
    let time_last_update_utc: String
    let time_next_update_unix: Int
    let time_next_update_utc: String
    let base_code: String
    let target_code: String
    let conversion_rate: Double
    
    init(result: String = "",
             documentation: String = "",
             terms_of_use: String = "",
             time_last_update_unix: Int = 0,
             time_last_update_utc: String = "",
             time_next_update_unix: Int = 0,
             time_next_update_utc: String = "",
             base_code: String = "",
             target_code: String = "",
             conversion_rate: Double = 0.0) {
            self.result = result
            self.documentation = documentation
            self.terms_of_use = terms_of_use
            self.time_last_update_unix = time_last_update_unix
            self.time_last_update_utc = time_last_update_utc
            self.time_next_update_unix = time_next_update_unix
            self.time_next_update_utc = time_next_update_utc
            self.base_code = base_code
            self.target_code = target_code
            self.conversion_rate = conversion_rate
        }
}
