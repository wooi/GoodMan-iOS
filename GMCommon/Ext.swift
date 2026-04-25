//
//  File.swift
//  GMCommon
//
//  Created by Wooi on 2024/1/7.
//

import Foundation
import SwiftUI
import UIKit

extension Double {
    func formattedString(decimalPlaces: Int) -> String {
        return String(format: "%.\(decimalPlaces)f", self)
    }
}


extension Color {
    init(hex: Int, opacity: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xff) / 255,
            green: Double((hex >> 08) & 0xff) / 255,
            blue: Double((hex >> 00) & 0xff) / 255,
            opacity: opacity
        )
    }
}


struct ScreenSize {
    static var screenHeight: CGFloat {
        return UIScreen.main.bounds.height
    }
    
    static var screenWidth: CGFloat {
        return UIScreen.main.bounds.width
    }
}

extension String {
    func widthOfString(usingFont font: UIFont) -> CGFloat {
         let fontAttributes = [NSAttributedString.Key.font: font]
         let size = self.size(withAttributes: fontAttributes)
         return size.width
     }
    
    func toDate() -> Date? {
        // 创建日期格式化器
        let dateFormatter = DateFormatter()
        // 设置日期格式
        dateFormatter.dateFormat = "dd MMMM yyyy"
        // 将字符串转换为日期
        return dateFormatter.date(from: self)
    }
    
    func stripTrailingZeros() -> String {
        var components = self.components(separatedBy: ".")
        if components.count == 2 {
            // Remove trailing zeros after the decimal point
            components[1] = components[1].replacingOccurrences(of: "0*$", with: "", options: .regularExpression)
            if components[1].isEmpty {
                return components[0]
            }
        }
        return components.joined(separator: ".")
    }
    
 }

let CircleFlagPrefix = "Circle_Flag_"

func addPrefix(to string: String) -> String {
    return CircleFlagPrefix + string
}


extension UIApplication {
    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}


