//
//  IVImage.swift
//  ImageViewer
//
//  Created by Akio Takei on 19/12/2017.
//  Copyright © 2017 Akio Takei. All rights reserved.
//

import ObjectMapper

class IVImage: Mappable {
    
    var key: String?
    var url: String?
    var width: Double?
    var height: Double?
    var createdDate: Double?

    func mapping(map: Map) {
        url <- map["url"]
        width <- map["width"]
        height <- map["height"]
        createdDate <- map["createdDate"]
    }
    
    required init?(map: Map) {
        
    }
    
    init() {
        
    }
}


class IVImageList: Mappable {
    
    var list: [String: IVImage]?
    
    func mapping(map: Map) {
        list <- map["images"]
    }
    
    required init?(map: Map) {
        
    }
}
