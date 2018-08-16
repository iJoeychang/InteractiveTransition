
import UIKit

class RevealAnimator: UIPercentDrivenInteractiveTransition, UIViewControllerAnimatedTransitioning, CAAnimationDelegate {

  let animationDuration = 2.0
  var operation: UINavigationControllerOperation = .push
  var interactive = false
  private var pausedTime: CFTimeInterval = 0
    
  weak var storedContext: UIViewControllerContextTransitioning?

  func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
    return animationDuration
  }

  func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
    storedContext = transitionContext

    // What you’re doing here is stopping the layer from running its own animations. This will freeze all sublayer animations as well.
    if interactive {
       let transitionLayer = transitionContext.containerView.layer
       pausedTime = transitionLayer.convertTime(CACurrentMediaTime(), from: nil)
       transitionLayer.speed = 0
       transitionLayer.timeOffset = pausedTime
    }
    
    if operation == .push {
      let fromVC = transitionContext.viewController(forKey: .from) as! MasterViewController
      let toVC = transitionContext.viewController(forKey: .to) as! DetailViewController

      transitionContext.containerView.addSubview(toVC.view)
      toVC.view.frame = transitionContext.finalFrame(for: toVC)

      let animation = CABasicAnimation(keyPath: "transform")
      animation.fromValue = NSValue(caTransform3D: CATransform3DIdentity)
      animation.toValue = NSValue(caTransform3D: CATransform3DConcat(
        CATransform3DMakeTranslation(0.0, -10.0, 0.0),
        CATransform3DMakeScale(150.0, 150.0, 1.0)
      ))

      animation.duration = animationDuration
      animation.delegate = self
      animation.fillMode = kCAFillModeForwards
      animation.isRemovedOnCompletion = false
      animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseIn)

      let maskLayer: CAShapeLayer = RWLogoLayer.logoLayer()
      maskLayer.position = fromVC.logo.position
      toVC.view.layer.mask = maskLayer
      maskLayer.add(animation, forKey: nil)

      fromVC.logo.add(animation, forKey: nil)

      let fadeIn = CABasicAnimation(keyPath: "opacity")
      fadeIn.fromValue = 0.0
      fadeIn.toValue = 1.0
      fadeIn.duration = animationDuration
      toVC.view.layer.add(fadeIn, forKey: nil)

    } else {

      let fromView = transitionContext.view(forKey: .from)!
      let toView = transitionContext.view(forKey: .to)!

      transitionContext.containerView.insertSubview(toView, belowSubview: fromView)

      UIView.animate(withDuration: animationDuration, delay: 0.0, options: .curveEaseIn, animations: {
        fromView.transform = CGAffineTransform(scaleX: 0.01, y: 0.01)
      }, completion: { _ in
        transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
      })
    }
  }

  func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
    if let context = storedContext {
      context.completeTransition(!context.transitionWasCancelled)
      //reset logo
      let fromVC = context.viewController(forKey: .from) as! MasterViewController
      fromVC.logo.removeAllAnimations()

      let toVC = context.viewController(forKey: .to) as! DetailViewController
      toVC.view.layer.mask = nil
    }
    storedContext = nil
  }
   
  // override update(_:)
  override func update(_ percentComplete: CGFloat) {
     super.update(percentComplete)
     // you’re calculating how far through the animation you are and setting the layer’s timeOffset accordingly, which moves the animations along to the appropriate point in the timeline
     let animationProgress = TimeInterval(animationDuration) * TimeInterval(percentComplete)
     storedContext?.containerView.layer.timeOffset = pausedTime + animationProgress
  }
    
  // Because you’re using layer animations, there is a little bit more work to do here. Remember you’d frozen the layer and were updating it manually; when you cancel or complete the transition you need to un-freeze it. Override cancel() and finish() like so:
  override func cancel() {
     restart(forFinishing: false)
     super.cancel()
  }
  override func finish() {
     restart(forFinishing: true)
     super.finish()
  }
  private func restart(forFinishing: Bool) {
     let transitionLayer = storedContext?.containerView.layer
     transitionLayer?.beginTime = CACurrentMediaTime()
     transitionLayer?.speed = forFinishing ? 1 : -1
  }
  
    
  func handlePan(_ recognizer: UIPanGestureRecognizer) {
    let translation = recognizer.translation(in:
        recognizer.view!.superview!)
    var progress: CGFloat = abs(translation.x / 200.0)
    progress = min(max(progress, 0.01), 0.99)
    switch recognizer.state {
        case .changed:
            update(progress)
        case .cancelled, .ended:
            if progress < 0.5 {
                cancel()
            } else {
                finish()
            }
            interactive = false
        default:
            break
    }
  }
}
