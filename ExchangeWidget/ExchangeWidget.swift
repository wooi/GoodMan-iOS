//
//  ExchangeWidget.swift
//  ExchangeWidget
//
//  Created by Wooi on 2023/12/21.
//

import WidgetKit
import SwiftUI

struct Provider: AppIntentTimelineProvider {
//    private let webRepository = ExchangeWebRepository()

    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), rateData: ExchangeRateApiData(), configuration: ConfigurationAppIntent())
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
        SimpleEntry(date: Date(), rateData: ExchangeRateApiData(), configuration: configuration)
    }

    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
        var rateData: ExchangeRateApiData? = nil

        do {
            let api = ApiRepository()
            rateData = try await api.fetchData()
            print("Error: \(String(describing: rateData))")
        } catch {

        }
        var entries: [SimpleEntry] = []
        let currentDate = Date()
        let entryDate = Calendar.current.date(byAdding: .day, value: 0, to: currentDate)!
        let entry = SimpleEntry(date: entryDate, rateData: rateData, configuration: configuration)
        entries.append(entry)

        return Timeline(entries: entries, policy: .atEnd)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let rateData: ExchangeRateApiData?
    let configuration: ConfigurationAppIntent
}

struct ExchangeWidgetEntryView: View {
    var entry: Provider.Entry

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Spacer()
                VStack(alignment: .leading) {
                    Text(entry.date, style: .date)
                        .padding(.top, 10)
                    HStack {
                        Text("🇺🇸")
                        Image(systemName: "arrowshape.forward.fill")
                            .foregroundColor(.white)
                        Text("🇨🇳")
                    }.font(.system(size: 16))
                        .padding(.top, 1)

                    Spacer()
                }
                    .foregroundColor(.white)
                    .font(.subheadline)
                Spacer()
            }
//            Text(entry.configuration.favoriteEmoji)
            Spacer()
            HStack {
                Spacer()
                if let rateData = entry.rateData {
                    Text(rateData.conversion_rate.formattedString(decimalPlaces: 4))
                        .font(.system(size: 40))
                        .foregroundColor(.white)
                } else {
                    Text("Rate data is nil")
                        .font(.title)
                        .foregroundColor(.red)
                }
                Spacer()
            }.padding(.bottom, 10)


        }.background(
            LinearGradient(
                gradient: Gradient(colors: [Color(hex: 0x4290F1), Color(hex: 0x375DD1)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
}

struct ExchangeWidget: Widget {
    let kind: String = "ExchangeWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
            ExchangeWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        } .contentMarginsDisabled()
    }
}

extension ConfigurationAppIntent {
    fileprivate static var smiley: ConfigurationAppIntent {
        let intent = ConfigurationAppIntent()
        intent.favoriteEmoji = "😀"
        return intent
    }
}

#Preview(as: .systemSmall) {
    ExchangeWidget()
} timeline: {
    SimpleEntry(date: .now, rateData: ExchangeRateApiData(conversion_rate: 7.1234), configuration: .smiley)
}
