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
  private(set) var viewControllers = [UIViewController]()
  private var peekContainerView = ContainerView()
  private var contentView = ContainerView()
  
  //options
  public var disableBounceIfNotingNext = true
  private var lockIdentity = false
  
  //temp
  private var peekContentDirectionType: DirectionType = .idle {
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
    
    let pan = UIPanGestureRecognizer(target: self, action: #selector(panAction(_:)))
    pan.delegate = self
    view.addGestureRecognizer(pan)
  }
  
  func panAction(_ sender: UIPanGestureRecognizer) {
    let translationY = sender.translation(in: self.view).y
    let velocityY = sender.velocity(in: self.view).y
    
    switch sender.state {
    case .began: fallthrough
    case .changed:
      var toY = translationY
      switch toY {
        case (let y) where y > 0: peekContentDirectionType = .next
        case (let y) where y < 0: peekContentDirectionType = .prev
        default: peekContentDirectionType = .idle
      }
      if lockIdentity {
        contentView.transform = CGAffineTransform.identity
      } else {
        contentView.transform = CGAffineTransform(translationX: 0, y: toY)
      }
    case .ended:
      var toY: CGFloat = 0.0
      var toDirectionType: DirectionType = .idle
      switch velocityY {
      case (let y) where y > 64 && peekContainerView.viewController != nil:
        toY =  view.bounds.height
        toDirectionType = .next
      case (let y) where y < -64 && peekContainerView.viewController != nil:
        toY = -view.bounds.height
        toDirectionType = .prev
      default: break
      }
      view.isUserInteractionEnabled = false
      
      let rangeY = abs(contentView.frame.origin.y - toY)
      let duration = min(rangeY / velocityY, 0.75)
      UIView.animate(withDuration: TimeInterval(duration), delay: 0.0, options: [.allowAnimatedContent, .curveEaseInOut] , animations: { [weak self] in
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
      }
    default: break
    }
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
        lockIdentity = false
        peekContainerView.viewController?.beginAppearanceTransition(false, animated: true)
        peekContainerView.viewController?.endAppearanceTransition()
        peekContainerView.configure(nil)
        addChildViewController(vc)
        peekContainerView.configure(vc)
        vc.didMove(toParentViewController: self)
        peekContainerView.viewController?.beginAppearanceTransition(true, animated: true)
      } else {
        peekContainerView.viewController?.beginAppearanceTransition(false, animated: true)
        peekContainerView.viewController?.endAppearanceTransition()
        peekContainerView.configure(nil)
        if disableBounceIfNotingNext {
          lockIdentity = true
        }
      }
    case .prev:
      if let vc = dataSource?.zappableViewController(self, viewControllerBefore: contentView.viewController) {
        lockIdentity = false
        peekContainerView.viewController?.beginAppearanceTransition(false, animated: true)
        peekContainerView.viewController?.endAppearanceTransition()
        peekContainerView.configure(nil)
        
        addChildViewController(vc)
        peekContainerView.configure(vc)
        vc.didMove(toParentViewController: self)
        peekContainerView.viewController?.beginAppearanceTransition(true, animated: true)
      } else {
        peekContainerView.viewController?.beginAppearanceTransition(false, animated: true)
        peekContainerView.viewController?.endAppearanceTransition()
        peekContainerView.configure(nil)
        if disableBounceIfNotingNext {
          lockIdentity = true
        }
      }
    case .idle: break
    }
  }
  
  //viewWillAppearとかの制御権を握る
  open override var shouldAutomaticallyForwardAppearanceMethods: Bool { return false }
}

extension ZappableViewController: UIGestureRecognizerDelegate {
  public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
    if let recog = gestureRecognizer as? UIPanGestureRecognizer {
      let velocity = recog.velocity(in: self.view)
      if abs(velocity.y) > abs(velocity.x) {
        return true
      }
    }
    return false
  }
}
