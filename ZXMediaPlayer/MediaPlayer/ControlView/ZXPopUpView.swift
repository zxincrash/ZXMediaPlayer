//
//  ZXPopUpView.swift
//  ZXValueTrackingSlider (https://github.com/zxin2928/ZXValueTrackingSlider)
//
//  Created by zhaoxin on 2017/11/20.
//  Copyright © 2017年 zhaoxin. All rights reserved.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import UIKit

extension CALayer {
    
    func addAnimation(animationKey:String, fromValue:Any, toValue:Any, customize customAnimationBlock:@escaping (CABasicAnimation)->Void){
        
        self.setValue(toValue, forKey: animationKey)
        let animal:CABasicAnimation = CABasicAnimation.init(keyPath: animationKey)
        animal.fromValue = fromValue
        if animal.fromValue == nil {
            animal.fromValue = self.presentation()?.value(forKey: animationKey)
        }
        animal.toValue = toValue
        
        customAnimationBlock(animal)
        
        self.add(animal, forKey: animationKey)
        
    }

}

@IBDesignable class ZXPopUpView: UIView {
    @IBInspectable private var _shouldAnimate:Bool = true
    @IBInspectable private var _animDuration:TimeInterval = 1
    @IBInspectable private var _pathLayer:CAShapeLayer?
    @IBInspectable private var _timeLabel:UILabel?
    @IBInspectable private var _textLayer:CATextLayer?
    private var _arrowCenterOffset:CGFloat! = 10
    
    var cornerRadius: CGFloat! = 4.0{
        didSet{
            _pathLayer?.path = self.pathForRect(rect: self.bounds, arrowOffset: _arrowCenterOffset).cgPath
            
            self.layer.cornerRadius = cornerRadius

        }

        
    }
    
    var arrowLength:CGFloat!{
        didSet{

        }
    }
    
    var widthPaddingFator:CGFloat? = 1.15
    
    var heightPaddingFactor:CGFloat? = 1.1
    
    @IBInspectable var color:UIColor! {
        didSet{
            _pathLayer?.fillColor = color.cgColor
        }

    }
    
    lazy var imageView:UIImageView = UIImageView.init(frame: CGRect.zero)
    @IBInspectable var image:UIImage!{
        didSet{
            self.imageView.image = image
        }
    }
    
    
    @IBInspectable var textColor:UIColor!{
        didSet{
            _timeLabel?.textColor = textColor
        }
    }
    
    @IBInspectable var font:UIFont!{
        didSet{
            _timeLabel?.font = font
        }
    
    }
    
    @IBInspectable var text:String!{
        didSet{
            _timeLabel?.text = text
        }
    }
    
    public func setFrame(frame:CGRect, arrowOffset:CGFloat){
        // only redraw path if either the arrowOffset or popUpView size has changed
        if (arrowOffset != _arrowCenterOffset || frame.size != self.frame.size) {
            _pathLayer?.path = self.pathForRect(rect: self.bounds, arrowOffset: _arrowCenterOffset).cgPath
        }
        
        _arrowCenterOffset = arrowOffset
        
        let anchorX:CGFloat = 0.5 + arrowOffset/(frame.width>0 ? frame.width: 1)
        self.layer.anchorPoint = CGPoint.init(x: anchorX, y: 1)
        self.layer.position = CGPoint.init(x: frame.minX + frame.width*anchorX, y: -1)
        self.layer.bounds = CGRect.init(origin: CGPoint.zero, size: frame.size)
        
    }
    
    // _shouldAnimate = YES; causes 'actionForLayer:' to return an animation for layer property changes
    // call the supplied block, then set _shouldAnimate back to NO
    public func animateBlock(block:@escaping(CFTimeInterval)->Void){
        _shouldAnimate = true
        _animDuration = 0.5
        
        let anim:CAAnimation = self.layer.animation(forKey: "position")!
        let elapsedTime:CFTimeInterval = min(CACurrentMediaTime() - anim.beginTime, anim.duration)
            _animDuration = _animDuration*elapsedTime/anim.duration
        
        block(_animDuration)
        _shouldAnimate = false
    }


    func showAnimated(animated:Bool){
        if !animated {
            self.layer.opacity = 1.0
            return
        }
        CATransaction.begin()
        // start the transform animation from scale 0.5, or its current value if it's already running
        let fromValue:NSValue = NSValue.init(caTransform3D: CATransform3DMakeScale(0.5, 0.5, 1))
        
        let toValue:NSValue = NSValue.init(caTransform3D: CATransform3DIdentity)
        
        self.layer.addAnimation(animationKey: "transform", fromValue: fromValue, toValue: toValue) { (anim) in
            anim.duration = 0.4
            anim.timingFunction = CAMediaTimingFunction.init(controlPoints: 0.8, 2.5, 0.35, 0.5)
        }
        self.layer.addAnimation(animationKey: "opacity", fromValue: fromValue, toValue: 1, customize: { (anim) in
            anim.duration = 0.1;
        })
        CATransaction.commit()
    }
    
    func hideAnimated(animated:Bool,
                      block completionBlock:@escaping()->Void){
        CATransaction.begin()
        CATransaction.setCompletionBlock {
            completionBlock()
            self.layer.transform = CATransform3DIdentity
        }
        
        let toValue:NSValue = NSValue.init(caTransform3D: CATransform3DMakeScale(0.5, 0.5, 1))

        if animated {
            self.layer.addAnimation(animationKey: "transform", fromValue: 0, toValue: toValue) { (anim) in
                anim.duration = 0.55
                anim.timingFunction = CAMediaTimingFunction.init(controlPoints: 0.1, 02, 0.3, 3)
            }
            self.layer.addAnimation(animationKey: "opacity", fromValue: 0.0, toValue: 0.0, customize: { (anim) in
                anim.duration = 0.75
            })
        }else{
            self.layer.opacity = 0.0
        }
        CATransaction.commit()

    }
    
    // if ivar _shouldAnimate) is YES then return an animation
    // otherwise return NSNull (no animation)
    override func action(for layer: CALayer, forKey event: String) -> CAAction? {
        if _shouldAnimate {
            let anim:CABasicAnimation = CABasicAnimation.init(keyPath: event)
            anim.beginTime = CACurrentMediaTime()
            anim.timingFunction = CAMediaTimingFunction.init(name: kCAMediaTimingFunctionEaseInEaseOut)
            anim.fromValue = layer.presentation()?.value(forKey: event)
            anim.duration = _animDuration
            
            return anim
        } else{
            return NSNull.init()
        }
    }
    
    
    //MARK:  public
    override init(frame: CGRect) {
        super.init(frame: frame)
        _shouldAnimate = false
        self.isUserInteractionEnabled = false
        
        _pathLayer = CAShapeLayer()// ivar can now be accessed without casting to CAShapeLayer every time
        self.layer.addSublayer(_pathLayer!)
        
        cornerRadius = 4.0
        arrowLength = 13.0
        
        _timeLabel = UILabel.init()
        _timeLabel?.text = "10:00";
        _timeLabel?.font = UIFont.systemFont(ofSize: 12)
        _timeLabel?.textAlignment = NSTextAlignment.center
        _timeLabel?.textColor = UIColor.red
        self.addSubview(_timeLabel!)

        self.addSubview(self.imageView)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    

    //MARK: private
    func pathForRect(rect:CGRect, arrowOffset:CGFloat)->UIBezierPath{
        if rect == CGRect.zero {
            return UIBezierPath()
        }
        
        // ensure origin is CGPoint.zero
        let pathRect:CGRect = CGRect.init(origin: CGPoint.zero, size: rect.size)
        
        // Create rounded rect
        var roundedRect:CGRect = pathRect
        roundedRect.size.height -= self.arrowLength
        
        // Create arrow path
        let popUpPath:UIBezierPath = UIBezierPath.init(roundedRect: roundedRect, cornerRadius: self.cornerRadius)
        
        // prevent arrow from extending beyond this point
        let maxX:CGFloat = roundedRect.maxX
        let arrowTipX:CGFloat = pathRect.midX + arrowOffset
        let tip:CGPoint = CGPoint.init(x: arrowTipX, y: pathRect.maxY)
        
        let arrowLength:CGFloat = roundedRect.height*0.5
        let x:CGFloat = arrowLength*CGFloat(tan(45.0*Double.pi/180))// x = half the length of the base of the arrow
        
        let arrowPath:UIBezierPath = UIBezierPath()
        arrowPath.move(to: tip)
        arrowPath.addLine(to: CGPoint.init(x: max(arrowTipX-x,0), y: roundedRect.maxY-arrowLength))
        arrowPath.addLine(to: CGPoint.init(x: min(arrowTipX+x,maxX), y: roundedRect.maxY-arrowLength))
        arrowPath.close()
        
        popUpPath.append(arrowPath)
        
        return popUpPath
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        
        let textRect:CGRect = CGRect.init(x: self.bounds.origin.x, y: 0, width: self.bounds.width, height: 13)
        _timeLabel?.frame = textRect
        
        let imageReact:CGRect  = CGRect.init(x: self.bounds.origin.x + 5, y: textRect.maxY + 3, width: self.bounds.size.width - 10, height: 56)
        self.imageView.frame = imageReact

    }

}
