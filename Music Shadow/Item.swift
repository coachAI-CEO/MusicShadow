//
//  Item.swift
//  Music Shadow
//
//  Created by macbook on 11/16/25.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
