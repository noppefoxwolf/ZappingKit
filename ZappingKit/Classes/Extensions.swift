//
//  Extensions.swift
//  Pods
//
//  Created by Tomoya Hirano on 2016/10/11.
//
//

import UIKit

internal struct FillConstraintsPair {
  fileprivate var v: [NSLayoutConstraint]
  fileprivate var h: [NSLayoutConstraint]
  
  internal init(of view: UIView, name: String? = nil) {
    let viewName = name ?? view.className
    let views    = [viewName: view]
    let vConstraints = NSLayoutConstraint.constraints(withVisualFormat: "V:|[\(viewName)]|",
      options: .alignAllLeft,
      metrics: nil,
      views: views)
    let hConstraints = NSLayoutConstraint.constraints(withVisualFormat: "H:|[\(viewName)]|",
      options: .alignAllLeft,
      metrics: nil,
      views: views)
    v = vConstraints
    h = hConstraints
  }
}

fileprivate extension NSObject {
  fileprivate static var className: String {
    return NSStringFromClass(self).components(separatedBy: ".").last!
  }
  
  fileprivate var className: String {
    return type(of: self).className
  }
}

internal extension UIView {
  public func addConstraints(_ fillConstraintsPair: FillConstraintsPair) {
    addConstraints(fillConstraintsPair.v)
    addConstraints(fillConstraintsPair.h)
  }
}
