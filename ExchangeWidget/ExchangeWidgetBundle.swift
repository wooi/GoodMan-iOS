//
//  ExchangeWidgetBundle.swift
//  ExchangeWidget
//
//  Created by Wooi on 2023/12/21.
//

import WidgetKit
import SwiftUI

@main
struct ExchangeWidgetBundle: WidgetBundle {
    var body: some Widget {
        ExchangeWidget()
        ExchangeWidgetLiveActivity()
    }
}
