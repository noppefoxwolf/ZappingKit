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
  private(set) var viewController: UIViewController? = nil
  
  func configure(_ viewController: UIViewController?) {
    if let view = viewController?.view {
      self.viewController = viewController
      view.translatesAutoresizingMaskIntoConstraints = false
      addSubview(view)
      addConstraints(FillConstraintsPair(of: view))
    } else {
      if let vc = self.viewController {
        vc.willMove(toParentViewController: nil)
        vc.view.removeFromSuperview()
        vc.removeFromParentViewController()
      }
      self.viewController = nil
    }
  }
}
