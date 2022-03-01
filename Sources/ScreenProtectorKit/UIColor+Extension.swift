//
//  File.swift
//  
//
//  Created by Endtry on 1/3/2565 BE.
//

import UIKit

extension UIColor {
    
    convenience init(hexString: String, alpha: CGFloat = 1) {
        self.init(hexa: UInt(hexString.dropFirst(), radix: 16) ?? 0, alpha: alpha)
    }
    
    convenience init(hexa: UInt, alpha: CGFloat = 1) {
        self.init(
            red:   .init((hexa & 0xff0000) >> 16) / 255,
            green: .init((hexa & 0xff00  ) >>  8) / 255,
            blue:  .init( hexa & 0xff    )        / 255,
            alpha: alpha
        )
    }
}
