//
//  CategoryFilter.swift
//  VaultDomain
//
//  Created by Miguel Solans on 18/11/2026.
//

import Foundation

public enum CategoryFilter {
    case any
    case matching(CategoryEntity)
    case excluding(CategoryEntity)
}
