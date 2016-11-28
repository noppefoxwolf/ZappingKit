//
//  ZappableViewController.swift
//  Pods
//
//  Created by Tomoya Hirano on 2016/10/11.
//
//

import UIKit
import RxSwift
import RxCocoa

public protocol ZappableViewControllerDataSource: class {
  func zappableViewController(_ zappableViewController: ZappableViewController, viewControllerBefore viewController: UIViewController?) -> UIViewController?
  func zappableViewController(_ zappableViewController: ZappableViewController, viewControllerAfter viewController: UIViewController?)  -> UIViewController?
}

public protocol ZappableViewControllerDelegate: class { }

open class ZappableViewController: UIViewController {
  enum DirectionType {
    case before
    case idle
    case after
    
    static func type(translationY: CGFloat) -> DirectionType {
      switch translationY {
        case (let y) where y > 0: return .after
        case (let y) where y < 0: return .before
        default: return .idle
      }
    }
  }
  
  weak public var delegate: ZappableViewControllerDelegate? = nil
  weak public var dataSource: ZappableViewControllerDataSource? = nil
  private var peekContainerView = ContainerView()
  private var contentView = ContainerView()
  
  //options
  public var disableBounceIfNotingNext = true
  private var lockIdentity = false
  public var validVelocityOffset: CGFloat = 0.0
  //temp
  private var directionHandler = PublishSubject<DirectionType>()
  private var peekContentType = BehaviorSubject<DirectionType>(value: .idle)
  private var pushPublisher = PublishSubject<CGFloat>()
  private var isScrollEnable = false
  private var isNeedEndAppearanceContentView = false
  private var disposeBag = DisposeBag()
  
  open override func viewDidLoad() {
    super.viewDidLoad()
    setup()
    setupSubscriber()
  }
  
  private func setup() {
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
  
  private func setupSubscriber() {
    directionHandler.distinctUntilChanged().asDriver(onErrorJustReturn: .idle).drive(onNext: { [weak self] (type) in
      self?.preparePeekContentView(with: type)
    }).addDisposableTo(disposeBag)
    
    pushPublisher.map { [weak self] (velocityY) -> (DirectionType, CGFloat) in
      guard let value = try? self?.peekContentType.value(), let currentDirection = value else { return (.idle, velocityY) }
      switch currentDirection {
      case .after  where velocityY <= 0: return (.idle, velocityY)
      case .before where velocityY >= 0: return (.idle, velocityY)
      default: return (currentDirection, velocityY)
      }
    }.filter({ [weak self] (type, velocityY) -> Bool in
      guard let value = try? self?.peekContentType.value(), let currentDirection = value else { return false }
      return !(currentDirection == .idle && type == .idle && !self!.isNeedEndAppearanceContentView)
    }).asDriver(onErrorJustReturn: (.idle, 0.0)).drive(onNext: { [weak self] (type, velocityY) in
      guard let _self = self else { return }
      var toY: CGFloat = 0.0
      switch type {
      case .after:  toY = _self.view.bounds.height
      case .before: toY = -_self.view.bounds.height
      default: break
      }
      let rangeY = abs(_self.contentView.frame.origin.y - toY)
      let duration = min(rangeY / velocityY, 0.75)
      
      switch type {
      case .after, .before:
        self?.view.isUserInteractionEnabled = false
        UIView.animate(withDuration: TimeInterval(duration), delay: 0.0, options: .allowAnimatedContent, animations: {
          self?.contentView.transform = CGAffineTransform(translationX: 0, y: toY)
        }, completion: { [weak self] (_) in
          self?.peekContainerView.viewController?.endAppearanceTransition()
          
          self?.isNeedEndAppearanceContentView = false
          self?.contentView.viewController?.endAppearanceTransition()
          self?.contentView.viewController?.willMove(toParentViewController: nil)
          self?.contentView.viewController?.view.removeFromSuperview()
          self?.contentView.viewController?.removeFromParentViewController()
          self?.contentView.viewController = nil
          
          if let vc = self?.peekContainerView.viewController {
            self?.peekContainerView.viewController = nil
            vc.view.removeFromSuperview()
            self?.contentView.viewController = vc
            self?.contentView.addSubview(vc.view)
            self?.contentView.addConstraints(FillConstraintsPair(of: vc.view))
            self?.contentView.viewController?.endAppearanceTransition()
            self?.contentView.transform = CGAffineTransform.identity
            
            self?.directionHandler.onNext(.idle)
          }
          self?.view.isUserInteractionEnabled = true
        })
      default:
        self?.view.isUserInteractionEnabled = false
        UIView.animate(withDuration: TimeInterval(duration), delay: 0.0, options: .allowAnimatedContent, animations: {
          self?.contentView.transform = CGAffineTransform.identity
        }, completion: { (_) in
          self?.peekContainerView.viewController?.beginAppearanceTransition(false, animated: false)
          self?.peekContainerView.viewController?.endAppearanceTransition()
          self?.peekContainerView.viewController?.willMove(toParentViewController: nil)
          self?.peekContainerView.viewController?.view.removeFromSuperview()
          self?.peekContainerView.viewController?.removeFromParentViewController()
          self?.peekContainerView.viewController = nil
          
          self?.isNeedEndAppearanceContentView = false
          self?.contentView.viewController?.beginAppearanceTransition(true, animated: true)
          self?.contentView.viewController?.endAppearanceTransition()
          
          self?.directionHandler.onNext(.idle)
          self?.view.isUserInteractionEnabled = true
        })
      }
    }).addDisposableTo(disposeBag)
  }
  
  private func preparePeekContentView(with type: DirectionType) {
    var vc: UIViewController? = nil
    switch type {
    case .after:
      vc = dataSource?.zappableViewController(self, viewControllerAfter:  contentView.viewController)
    case .before:
      vc = dataSource?.zappableViewController(self, viewControllerBefore:  contentView.viewController)
    default: break
    }
    isScrollEnable = (vc != nil)
    
    peekContainerView.viewController?.beginAppearanceTransition(false, animated: false)
    peekContainerView.viewController?.endAppearanceTransition()
    peekContainerView.viewController?.willMove(toParentViewController: nil)
    peekContainerView.viewController?.view.removeFromSuperview()
    peekContainerView.viewController?.removeFromParentViewController()
    peekContainerView.viewController = nil
    
    if let vc = vc {
      isNeedEndAppearanceContentView = true
      peekContentType.onNext(type)
      contentView.viewController?.beginAppearanceTransition(false, animated: true)
      
      vc.beginAppearanceTransition(true, animated: false)
      vc.view.translatesAutoresizingMaskIntoConstraints = false
      addChildViewController(vc)
      peekContainerView.viewController = vc
      peekContainerView.addSubview(vc.view)
      peekContainerView.addConstraints(FillConstraintsPair(of: vc.view))
      vc.didMove(toParentViewController: self)
    } else {
      peekContentType.onNext(.idle)
    }
  }
  
  @objc private func panAction(_ sender: UIPanGestureRecognizer) {
    let translationY = sender.translation(in: self.view).y
    let velocityY = sender.velocity(in: self.view).y
    switch sender.state {
    case .began, .changed:
      directionHandler.onNext(DirectionType.type(translationY: translationY))
      if isScrollEnable {
        contentView.transform = CGAffineTransform(translationX: 0, y: translationY)
      }
    case .ended:
      pushPublisher.onNext(velocityY)
    default: break
    }
  }
  
  open override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    contentView.viewController?.beginAppearanceTransition(true, animated: animated)
    contentView.viewController?.endAppearanceTransition()
  }
  
  open override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    contentView.viewController?.beginAppearanceTransition(false, animated: animated)
    contentView.viewController?.endAppearanceTransition()
  }
  
  //Must call in viewDidLoad
  public func first(_ viewController: UIViewController) {
    //viewController.beginAppearanceTransition(true, animated: false)
    viewController.view.translatesAutoresizingMaskIntoConstraints = false
    addChildViewController(viewController)
    contentView.viewController = viewController
    contentView.addSubview(viewController.view)
    contentView.addConstraints(FillConstraintsPair(of: viewController.view))
    viewController.didMove(toParentViewController: self)
    //viewController.endAppearanceTransition()
  }
  
  //viewWillAppearとかの制御権を握る
  open override var shouldAutomaticallyForwardAppearanceMethods: Bool { return false }
}

extension ZappableViewController: UIGestureRecognizerDelegate {
  public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
    if let recog = gestureRecognizer as? UIPanGestureRecognizer {
      let velocity = recog.velocity(in: self.view)
      if abs(velocity.y) > abs(velocity.x) && validVelocityOffset < abs(velocity.y) {
        return true
      }
    }
    return false
  }
}
