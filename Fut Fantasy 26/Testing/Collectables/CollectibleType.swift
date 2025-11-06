//
//  CollectibleType.swift
//  Fut Fantasy 26
//
//  Created by Jose julian Lopez on 06/11/25.
//


import Foundation
import SwiftData
import SwiftUI
import UIKit

enum CollectibleType: String, Codable {
    case badge
    case sticker
}

@Model
final class Collectible {
    @Attribute(.unique) var id: UUID
    var type: CollectibleType
    var name: String
    var createdAt: Date
    
    var imageName: String?
    
    @Attribute(.externalStorage) var stickerData: Data?
    
    var squad: Squad?
    
    init(type: CollectibleType, name: String, imageName: String? = nil, stickerData: Data? = nil, createdAt: Date = .now) {
        self.id = UUID()
        self.type = type
        self.name = name
        self.imageName = imageName
        self.stickerData = stickerData
        self.createdAt = createdAt
    }
    
        @Transient
        var uiImage: UIImage? {
            if type == .sticker, let data = stickerData {
                return UIImage(data: data)
            } else if type == .badge, let name = imageName {
                return UIImage(named: name)
            }
            return nil
        }

    @Transient
    var displayImage: Image? {
        if type == .sticker, let data = stickerData, let uiImage = UIImage(data: data) {
            return Image(uiImage: uiImage)
        } else if type == .badge, let name = imageName {
            return Image(name)
        }
        return nil 
    }
}
