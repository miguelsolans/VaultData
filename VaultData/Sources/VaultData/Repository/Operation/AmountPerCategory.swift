//
//  AmountPerCategory.swift
//  VaultData
//
//  Created by Miguel Solans on 15/10/2026.
//

import Foundation

public struct AmountPerCategory: Identifiable {
    
    public let id: UUID

    public let title: String
    
    public let amount: Double
    
    public let hexColor: String
}
