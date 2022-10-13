//
//  CustomCorners.swift
//  FyreKit
//
//  Created by Dane Wilson on 2/26/22.
//

import SwiftUI

public struct CustomCorners: Shape {
  var corners: UIRectCorner
  var radius: CGFloat
  
  public func path(in rect: CGRect) -> Path {
    let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))

    return Path(path.cgPath)
  }
}
