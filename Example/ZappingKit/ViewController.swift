//
//  ViewController.swift
//  ZappingKit
//
//  Created by Tomoya Hirano on 10/11/2016.
//  Copyright (c) 2016 Tomoya Hirano. All rights reserved.
//

import UIKit
import ZappingKit

final class ViewController: ZappableViewController, ZappableViewControllerDelegate, ZappableViewControllerDataSource {
  override func viewDidLoad() {
    super.viewDidLoad()
    delegate = self
    dataSource = self
    
    let vc = ItemViewController()
    vc.index = 0
    first(vc)
  }
  
  func zappableViewController(_ zappableViewController: ZappableViewController, viewControllerAfter viewController: UIViewController?) -> UIViewController? {
    guard let current = viewController as? ItemViewController else { return nil }
    var index = current.index + 1
    if index >= Colors.shared.colors.count {
      index = 0
    }
    let vc = ItemViewController()
    vc.index = index
    return vc
  }
  
  func zappableViewController(_ zappableViewController: ZappableViewController, viewControllerBefore viewController: UIViewController?) -> UIViewController? {
    return nil
    guard let current = viewController as? ItemViewController else { return nil }
    var index = current.index - 1
    if index < 0 {
      index = Colors.shared.colors.count - 1
    }
    let vc = ItemViewController()
    vc.index = index
    return vc
  }
}

class Colors {
  static let shared = Colors()
  var colors = { (0...10).map { _ in UIColor.getRandomColor() } }()
}

final class ItemViewController: UIViewController {
  var index: Int = 0
  private var label = UILabel()
  override func viewDidLoad() {
    super.viewDidLoad()
    view.addSubview(label)
    view.backgroundColor = Colors.shared.colors[index]
    label.frame = view.bounds
    label.textAlignment  = .center
    label.font = UIFont.boldSystemFont(ofSize: 42)
    label.text = "\(index): viewDidLoad"
    print(label.text)
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    label.text = "\(index): viewWillAppear"
    print(label.text)
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    label.text = "\(index): viewDidAppear"
    print(label.text)
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    label.text = "\(index): viewWillDisappear"
    print(label.text)
  }
  
  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    label.text = "\(index): viewDidDisappear"
    print(label.text)
  }
  
  override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
    print(navigationController)
  }
}

extension UIColor {
  static func getRandomColor() -> UIColor {
    let randomRed:CGFloat = CGFloat(drand48())
    let randomGreen:CGFloat = CGFloat(drand48())
    let randomBlue:CGFloat = CGFloat(drand48())
    return UIColor(red: randomRed, green: randomGreen, blue: randomBlue, alpha: 1.0)
  }
}
