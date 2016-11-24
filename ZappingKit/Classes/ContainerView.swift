//
//  ContainerView.swift
//  Pods
//
//  Created by Tomoya Hirano on 2016/10/11.
//
//

import UIKit

class ContainerView: UIView {
  //weakにしたい
  var viewController: UIViewController? = nil
  
//  func configure(_ viewController: UIViewController?) {
//    if let view = viewController?.view {
//      self.viewController = viewController
//      view.translatesAutoresizingMaskIntoConstraints = false
//      addSubview(view)
//      addConstraints(FillConstraintsPair(of: view))
//    } else {
//      self.viewController?.view.removeFromSuperview()
//      self.viewController = nil
//    }
//  }
}
