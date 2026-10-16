//
//  File.swift
//  VaultCore
//
//  Created by Miguel Solans on 01/10/2026.
//

import Foundation
import VaultDomain

extension DashboardWidget {
    public var widgetType: DashboardWidgetType {
        get {
            return DashboardWidgetType(rawValue: type) ?? .unknown
        }
        set {
            type = newValue.rawValue
        }
    }
}
