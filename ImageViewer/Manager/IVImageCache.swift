//
//  IVImageCache.swift
//  ImageViewer
//
//  Created by Akio Takei on 19/12/2017.
//  Copyright © 2017 Akio Takei. All rights reserved.
//

import UIKit

class IVImageCache {
    static let shared = IVImageCache()
    var images: [String: UIImage] = [:]
}
