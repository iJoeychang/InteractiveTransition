###### 创建 interactive transition

接 iOS 动画十六例，我们在上一节的 demo 上继续实践。

interaction controller 动画管理类可以和上一节 animation controller 中的为同一个，当两个控制器在同一个类中时，执行某些任务会更容易一些。我们只需要确保该类遵循 UIViewControllerAnimatedTransitioning 和UIViewControllerInteractiveTransitioning 协议就好了。

UIViewControllerInteractiveTransitioning 只有一个必需的方法startInteractiveTransition(_:)  -- 它将 transitioning context 作为其参数。

interaction controller 会定期调用 updateInteractiveTransition(_:) 来移动 transition 。

###### 操纵 pan 手势

在 MasterViewController 的 viewDidAppear 方法中添加手势识别：

```
 override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    
    // add the tap gesture recognizer
    // let tap = UITapGestureRecognizer(target: self, action: #selector(didTap))
    // view.addGestureRecognizer(tap)
    
    let pan = UIPanGestureRecognizer(target: self, action: #selector(didPan(_:)))
    view.addGestureRecognizer(pan)
    
    // add the logo to the view
    logo.position = CGPoint(x: view.layer.bounds.size.width/2,
      y: view.layer.bounds.size.height/2 - 30)
    logo.fillColor = UIColor.white.cgColor
    view.layer.addSublayer(logo)
  }
```


###### 使用 interactive animator 类

UIPercentDrivenInteractiveTransition 类遵循 UIViewControllerInteractiveTransitioning 协议，它允许我们获取和设置 transition 的进度。

这给我们带来了极大方便，因为我们可以使用此类相应地调整 percentComplete 属性并调用 update() 来设置 transition 的当前进度。

打开 RevealAnimator.swift ，更新类定义：
```
class RevealAnimator: UIPercentDrivenInteractiveTransition, UIViewControllerAnimatedTransitioning, CAAnimationDelegate {
```
>注意，这里 UIPercentDrivenInteractiveTransition 是类，而不是协议。UIViewControllerAnimatedTransitioning, CAAnimationDelegate 是协议。

定义变量属性 interactive，据此决定 animator 是否应该以交互方式进行 transition：

```
var interactive = false
```

打开 MasterViewController.swift 类，在 MasterViewController extension 中添加如下代理方法：

```
func navigationController(_
        navigationController:UINavigationController,
    interactionControllerFor
        animationController:UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        if !transition.interactive {
            return nil
        }
        return transition
    }
```
只有 transition 为交互式时才返回 interaction controller 。

在 MasterViewController 中实现 Pan 手势方法:
```
 @objc func didPan(_ recognizer: UIPanGestureRecognizer) {
    switch recognizer.state {
    case .began:
        transition.interactive = true
        performSegue(withIdentifier: "details", sender: nil)
    default:
        transition.handlePan(recognizer)
    }
  }
``` 
运行项目，使用 Pan 手势，可以看到效果了。在 MasterViewController 页面无论左滑、右滑，都会 push 到下一页面。

###### 计算 animation 的进度

平移 (Pan) 手势，最重要的一点是，确定过渡 (transition) 应该滑动多远。

打开 RevealAnimator.swift ，在 handlePan() 方法中添加如下代码：

```
let translation = recognizer.translation(in:
recognizer.view!.superview!)
var progress: CGFloat = abs(translation.x / 200.0) 
progress = min(max(progress, 0.01), 0.99)
```
首先，我们从平移手势识别器得到 translation，translation 让我们知道用户在 X和 Y 轴上移动 ﬁnger(手指)/stylus(触控笔)/appendage/whatever(其它东东) 的距离。 从逻辑上讲，用户从初始位置移动的越远，translation 的进度就越大。

这里我们使用 200 points 作为移动距离的一个参考，当然你也可以使用其它值。使用 abs() 方法取绝对值，这样处理后，无论是向左还是向右滑动，都会有相同效果。

在 handlePan():方法中添加如下代码：
```
switch recognizer.state { 
    case .changed:
          update(progress)
    default:
         break 
}
```
update() 是 UIPercentDrivenInteractiveTransition 类中设置 translation 动画当前进度的方法。在 OC 中，对应的是 [self updateInteractiveTransition:progress] 方法。

build and run 我们的 demo，我们会看到一些动画似乎跟随你的手势而其它动画只是按照它们自己的节奏运行。 UIPercentDrivenInteractiveTransition是 view animations，它不如 layer animations 看起来那么好，所以接下来我们还需要再优化一下。

在 RevealAnimator 中添加如下属性：

```
private var pausedTime: CFTimeInterval = 0
```
在 animateTransition(using:): 顶部添加如下代码：

```
if interactive { 
    let transitionLayer = transitionContext.containerView.layer 
    pausedTime = transitionLayer.convertTime(CACurrentMediaTime(), from: nil)       
    transitionLayer.speed = 0 
    transitionLayer.timeOffset = pausedTime
 }
```
这里做的是阻止 layer 运行自己的动画，这将冻结所有子图层动画。

重载 update(_:) 方法：

```
override func update(_ percentComplete: CGFloat) {     
    super.update(percentComplete) 
    let animationProgress = TimeInterval(animationDuration) * TimeInterval(percentComplete)
    storedContext?.containerView.layer.timeOffset = pausedTime + animationProgress 
}
```
计算动画的距离并相应地设置图层的 timeOffset，这会将动画移动到时间轴 (timeline) 中的适当点。

由于转换 (transition) 还不是很完整，因此只要抬起手指，整个导航就会中断。

###### 处理终结 (early termination)

UIPercentDrivenInteractiveTransition 提供了几种方法，调用它们，可以根据用户的操作来恢复 (revert) 或完成(complete)  transition。

在 switch statement 中添加如下代码：

```
case .cancelled, .ended:
if progress < 0.5 { 
     cancel()
} else {
     finish()
}
```

这里意思是，如果拖动距离小于 100 points，取消动画，拖动距离大于 100 points，完成动画。如图：

![cancel or finish](https://upload-images.jianshu.io/upload_images/130752-cbc2a92db6da5a1a.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

重载 cancel() 和 finish() 方法：
```
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
```
取消时，需要将 layer 设置为向后运行，因此速度设置为-1。

##### 手势滑动实现 UINavigationController Pop 动画

在 DetailViewController 定义属性：
  
```
weak var animator: RevealAnimator?
```

接着在 DetailViewController 的 viewDidAppear 方法添加手势识别：
   
```
override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    if let masterVC = navigationController!.viewControllers.first as? MasterViewController {
       animator = masterVC.transition
    }
        
    let pan = UIPanGestureRecognizer(target: self, action: #selector(didPan))
    view.addGestureRecognizer(pan)
}
```

实现 didPan 方法：
 
```
@objc func didPan(recognizer: UIPanGestureRecognizer) {
    guard let animator = animator else { return }
    if recognizer.state == .began {
        animator.interactive = true
        navigationController!.popViewController(animated: true)
    }
    animator.handlePan(recognizer)
}
```

这样就可以在 DetailViewController 页面，手势左滑、右滑实现 pop 动画了。非常实用的一个功能。

最终效果图：
![Interactive Transitions](https://upload-images.jianshu.io/upload_images/130752-e50478c5ffeb7afd.gif?imageMogr2/auto-orient/strip)
