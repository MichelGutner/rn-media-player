//
//  UIView.swift
//  Pods
//
//  Created by Michel Gutner on 23/02/25.
//

extension UIWindow {
    func safeAreaInsetsIfAvailable() -> UIEdgeInsets? {
        if #available(iOS 11.0, *) {
            return self.safeAreaInsets
        }
        return nil
    }
}
