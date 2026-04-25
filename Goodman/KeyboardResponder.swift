//
//  KeyboardResponder.swift
//  Goodman
//
//  Created by Wooi on 2024/3/30.
//

import SwiftUI
import Combine

class KeyboardResponder: ObservableObject {
    private var cancellable: AnyCancellable?
    @Published var keyboardHeight: CGFloat = 0

    init() {
        let willShow = NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
        let willHide = NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)

        cancellable = Publishers.Merge(willShow, willHide)
            .compactMap { notification in
                notification.name == UIResponder.keyboardWillShowNotification ? notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect : CGRect.zero
            }
            .map { rect in
                rect.height
            }
            .subscribe(on: DispatchQueue.main)
            .assign(to: \.keyboardHeight, on: self)
    }
}
