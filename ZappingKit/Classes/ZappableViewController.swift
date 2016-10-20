//
//  ZappableViewController.swift
//  Pods
//
//  Created by Tomoya Hirano on 2016/10/11.
//
//

import UIKit

public protocol ZappableViewControllerDataSource {
  func zappableViewController(_ zappableViewController: ZappableViewController, viewControllerBefore viewController: UIViewController?) -> UIViewController?
  func zappableViewController(_ zappableViewController: ZappableViewController, viewControllerAfter viewController: UIViewController?)  -> UIViewController?
}

public protocol ZappableViewControllerDelegate {
  
}

open class ZappableViewController: UIViewController {
  enum DirectionType {
    case prev
    case idle
    case next
  }
  
  public var delegate: ZappableViewControllerDelegate? = nil
  public var dataSource: ZappableViewControllerDataSource? = nil
  public var scrollOffset: CGFloat = 44.0
  var viewControllers = [UIViewController]()
  
  fileprivate var peekContainerView = ContainerView()
  fileprivate var contentView = ContainerView()
  
  //temp
  fileprivate var initialY: CGFloat = 0.0
  fileprivate var peekContentDirectionType: DirectionType = .idle {
    didSet {
      if oldValue != peekContentDirectionType {
        peekContentDirectionTypeChanged(peekContentDirectionType)
      }
    }
  }
  
  open override func viewDidLoad() {
    super.viewDidLoad()
    
    peekContainerView.translatesAutoresizingMaskIntoConstraints = false
    contentView.translatesAutoresizingMaskIntoConstraints = false
    
    view.addSubview(peekContainerView)
    view.addSubview(contentView)
    
    view.addConstraints(FillConstraintsPair(of: peekContainerView, name: "peekContainerView"))
    view.addConstraints(FillConstraintsPair(of: contentView, name: "contentView"))
  }
  
  open override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    contentView.viewController?.beginAppearanceTransition(true, animated: true)
    contentView.viewController?.endAppearanceTransition()
  }
  
  open override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    contentView.viewController?.beginAppearanceTransition(false, animated: true)
    contentView.viewController?.endAppearanceTransition()
  }
  
  //Must call in viewDidLoad
  public func first(_ viewController: UIViewController) {
    viewControllers = [viewController]
    addChildViewController(viewController)
    contentView.configure(viewController)
    viewController.didMove(toParentViewController: self)
  }
  
  fileprivate func peekContentDirectionTypeChanged(_ type: DirectionType) {
    switch type {
    case .next:
      if let vc = dataSource?.zappableViewController(self, viewControllerAfter:  contentView.viewController) {
        peekContainerView.viewController?.beginAppearanceTransition(false, animated: true)
        peekContainerView.viewController?.endAppearanceTransition()
        peekContainerView.configure(nil)
        addChildViewController(vc)
        peekContainerView.configure(vc)
        vc.didMove(toParentViewController: self)
        peekContainerView.viewController?.beginAppearanceTransition(true, animated: true)
      } else {
      
      }
    case .prev:
      if let vc = dataSource?.zappableViewController(self, viewControllerBefore: contentView.viewController) {
        peekContainerView.viewController?.beginAppearanceTransition(false, animated: true)
        peekContainerView.viewController?.endAppearanceTransition()
        peekContainerView.configure(nil)
        
        addChildViewController(vc)
        peekContainerView.configure(vc)
        vc.didMove(toParentViewController: self)
        peekContainerView.viewController?.beginAppearanceTransition(true, animated: true)
      } else {
        
      }
    case .idle: break
    }
  }
  
  //viewWillAppearとかの制御権を握る
  open override var shouldAutomaticallyForwardAppearanceMethods: Bool { return false }
  
  fileprivate var isScolling = false
}

extension ZappableViewController {
  open override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    guard let touch = touches.first else { return }
    initialY = touch.location(in: contentView).y
    //contentView.viewController?.beginAppearanceTransition(false, animated: true)
  }
  
  open override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
    guard let touch = touches.first else { return }
    let transitionY = touch.location(in: view).y - initialY
    //初めて20以上の移動をした時
    if abs(transitionY) > scrollOffset && !isScolling {
      isScolling = true
      contentView.viewController?.beginAppearanceTransition(false, animated: true)
      UIView.animate(withDuration: 0.3, animations: { [weak self] in
        self?.contentView.transform = CGAffineTransform(translationX: 0, y: transitionY)
      })
    } else if isScolling {
      contentView.transform = CGAffineTransform(translationX: 0, y: transitionY)
      switch contentView.frame.origin.y {
      case (let y) where y > 0: peekContentDirectionType = .next
      case (let y) where y < 0: peekContentDirectionType = .prev
      default: peekContentDirectionType = .idle
      }
    }
  }
  
  open override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
    super.touchesCancelled(touches, with: event)
    completion()
  }
  
  open override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
    super.touchesEnded(touches, with: event)
    completion()
  }
  
  private func completion() {
    guard isScolling else { return }//just tap
    
    var toY: CGFloat = 0.0
    var toDirectionType: DirectionType = .idle
    switch contentView.frame.origin.y {
    case (let y) where y >  64 && peekContainerView.viewController != nil:
      toY =  view.bounds.height
      toDirectionType = .next
    case (let y) where y < -64 && peekContainerView.viewController != nil:
      toY = -view.bounds.height
      toDirectionType = .prev
    default: break
    }
    
    view.isUserInteractionEnabled = false
    UIView.animate(withDuration: 0.15, delay: 0.0, options: [.allowAnimatedContent, .curveEaseInOut] , animations: { [weak self] in
      self?.contentView.transform = CGAffineTransform(translationX: 0, y: toY)
    }) { [weak self] (_) in
      switch toDirectionType {
      case .next, .prev:
        self?.contentView.viewController?.endAppearanceTransition()
        self?.peekContainerView.viewController?.endAppearanceTransition()
        let vc = self?.peekContainerView.viewController
        self?.peekContainerView.configure(nil)
        self?.contentView.configure(nil)
        self?.contentView.configure(vc)
        self?.contentView.transform = CGAffineTransform.identity
        self?.peekContentDirectionType = .idle
      case .idle:
        self?.peekContainerView.viewController?.beginAppearanceTransition(false, animated: true)
        self?.peekContainerView.viewController?.endAppearanceTransition()
        self?.peekContainerView.configure(nil)
        self?.peekContentDirectionType = .idle
        self?.contentView.viewController?.beginAppearanceTransition(true, animated: true)
        self?.contentView.viewController?.endAppearanceTransition()
      }
      self?.view.isUserInteractionEnabled = true
      self?.isScolling = false
    }
  }
}
