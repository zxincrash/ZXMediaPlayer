//
//  ZXValueTrackingSlider.swift
//  ZXValueTrackingSlider (https://github.com/zxin2928/ZXValueTrackingSlider)
//
//  Created by zhaoxin on 2017/11/19.
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
protocol ZXValueTrackingSliderDelegate{
    func sliderWillDisplayPopUpView(slide:ZXValueTrackingSlider)
    
    func slideWillHidePopUpView(slide:ZXValueTrackingSlider)
    func slideDidHidePopUpView(slide:ZXValueTrackingSlider)
    
}

protocol ZXValueTrackingSliderDataSource {
    
}

@IBDesignable class ZXValueTrackingSlider: UISlider {
    
    // delegate is only needed when used with a TableView or CollectionView - see below
    var delegate: ZXValueTrackingSliderDelegate?
    // supply entirely customized strings for slider values using the datasource protocol - see below
    var dataSource: ZXValueTrackingSliderDataSource?
    
    var popUpView:ZXPopUpView?
    // take full control of the format dispayed with a custom NSNumberFormatter
    var numberFormatter:NumberFormatter?
    
    var popUpViewAlwaysOn:Bool?
    
    private var _keyTimes:Array<NSNumber>?
    private var _valueRange:Float?
    
    @IBInspectable var preImage:UIImage?{
        didSet{
            self.popUpView?.image = preImage
        }
    }
    
    @IBInspectable var textColor:UIColor?
    // font can not be nil, it must be a valid UIFont
    // default is ‘boldSystemFontOfSize:22.0’
    @IBInspectable var font:UIFont?{
        didSet{
            self.popUpView?.font = font
        }
    }
    
    @IBInspectable var preText:String?{
        didSet{
            self.popUpView?.text = preText
        }
    }
    
    // setting the value of 'popUpViewColor' overrides 'popUpViewAnimatedColors' and vice versa
    // the return value of 'popUpViewColor' is the currently displayed value
    // this will vary if 'popUpViewAnimatedColors' is set (see below)
    
    @IBInspectable var popUpViewColor:UIColor?{
        didSet{
            self.popUpView?.color = popUpViewColor != nil ? popUpViewColor : .black
            
        }
    }
    
    
    @IBInspectable var popUpViewBackgroundColor:UIColor?{
        didSet{
            self.popUpView?.backgroundColor = popUpViewBackgroundColor
        }
    }
    
    // cornerRadius of the popUpView, default is 4.0
    var popUpViewCornerRadious:CGFloat?{
        didSet{
            self.popUpView?.cornerRadius = popUpViewCornerRadious
        }
    }
    
    // arrow height of the popUpView, default is 13.0
    var popUpViewArrowLength:CGFloat?{
        didSet{
            self.popUpView?.arrowLength = popUpViewArrowLength
        }
    }
    // width padding factor of the popUpView, default is 1.15
    var popUpViewWidthPaddingFactor:CGFloat?{
        didSet{
            self.popUpView?.widthPaddingFator = popUpViewWidthPaddingFactor
        }
    }
    // height padding factor of the popUpView, default is 1.1
    var popUpViewHeightPaddingFactor:CGFloat?{
        didSet{
            self.popUpView?.heightPaddingFactor = popUpViewHeightPaddingFactor
        }
    }
    
    override var maximumValue: Float{
        didSet{
            _valueRange = maximumValue - self.minimumValue;
            
        }
        
    }
    
    override var minimumValue: Float{
        didSet{
            _valueRange = self.maximumValue - minimumValue
            
        }
        
    }
    
    // set max and min digits to same value to keep string length consistent
    func setMaxFractionDigitsDisplayed(maxDigits:Int) {
        self.numberFormatter?.maximumFractionDigits = maxDigits
        self.numberFormatter?.minimumFractionDigits = maxDigits
    }
    
    func showPopUpViewAnimated(animated:Bool){
        self.popUpViewAlwaysOn = true
        self._showPopUpViewAnimated(animated: animated)
    }
    
    func hidePopUpViewAnimated(animated:Bool){
        self.popUpViewAlwaysOn = false
        self._hidePopUpViewAnimated(animated: animated)
    }
    
    // when setting max FractionDigits the min value is automatically set to the same value
    // this ensures that the PopUpView frame maintains a consistent width
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setup()
    }
    
    //MARK:  private
    private func setup(){
        self.popUpViewAlwaysOn = false
        
        let formatter:NumberFormatter = NumberFormatter.init()
        formatter.numberStyle = NumberFormatter.Style.decimal
        formatter.roundingMode = NumberFormatter.RoundingMode.halfUp
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        self.numberFormatter = formatter
        
        self.popUpView = ZXPopUpView.init(frame: CGRect.zero)
        self.popUpViewColor = UIColor.init(hue: 0.6, saturation: 0.6, brightness: 0.5, alpha: 0.8)
        
        self.popUpView?.alpha = 0.0
        
        self.popUpView?.textColor = .white
        self.addSubview(self.popUpView!)

    }
    
    private func thumbRect() -> CGRect {
        return self.thumbRect(forBounds: self.bounds, trackRect: self.trackRect(forBounds: self.bounds), value: self.value)
    }
    

    private func updatePopUpView(){
        let popUpViewSize:CGSize = CGSize.init(width: 100, height: 56 + self.popUpViewArrowLength! + 20)
        
        // calculate the popUpView frame
        let thumbRect:CGRect = self.thumbRect()
        let thumW:CGFloat = thumbRect.size.width
        let thumH:CGFloat = thumbRect.size.height
        
        var popUpRect:CGRect = thumbRect.insetBy(dx: (thumW-popUpViewSize.width)*0.5, dy: (thumH-popUpViewSize.height)*0.5)
        popUpRect.origin.y = thumbRect.origin.y - popUpViewSize.height
        
        // determine if popUpRect extends beyond the frame of the progress view
        // if so adjust frame and set the center offset of the PopUpView's arrow
        let minOffsetX:CGFloat = popUpRect.minX
        let maxOffsetX:CGFloat = popUpRect.maxX - self.bounds.width
        
        let offset:CGFloat = minOffsetX<0.0 ? minOffsetX : (maxOffsetX>0.0 ? maxOffsetX : 0.0)
        popUpRect.origin.x -= offset
        self.popUpView?.setFrame(frame: popUpRect, arrowOffset: offset)
    }
    
    
    // takes an array of NSNumbers in the range self.minimumValue - self.maximumValue
    // returns an array of NSNumbers in the range 0.0 - 1.0
    private func keyTimesFromSliderPositions(positons:Array<NSNumber>)->NSMutableArray{
        
        let keyTimes:NSMutableArray = NSMutableArray.init()
        for num:NSNumber in positons.sorted(by: { (num1, num2) -> Bool in
            return num1.floatValue < num2.floatValue ? true : false
        }) {
            keyTimes.add(NSNumber.init(value: (num.floatValue - Float(self.minimumValue))/_valueRange!))
        }
        return keyTimes
    }
    
    private func _showPopUpViewAnimated(animated:Bool){
        if self.delegate != nil {
            self.delegate?.sliderWillDisplayPopUpView(slide: self)
        }
        self.popUpView?.showAnimated(animated: animated)
    }
    
    private func _hidePopUpViewAnimated(animated:Bool){
        self.delegate?.sliderWillDisplayPopUpView(slide: self)
        
        self.popUpView?.hideAnimated(animated: animated) {
            self.delegate?.slideDidHidePopUpView(slide: self)
        }
    }
    
    
    //MARK: - subclassed
    override func layoutSubviews() {
        super.layoutSubviews()
        self.updatePopUpView()
    }
    
    override func setValue(_ value: Float, animated: Bool) {
        if animated {
            self.popUpView?.animateBlock(block: {
                (duration) in

                self.layoutIfNeeded()
            })
        }else{
            super.setValue(value, animated: animated)
            
        }
    }
    
    override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        let begin:Bool = super.beginTracking(touch, with: event)
        if begin && !self.popUpViewAlwaysOn! {
            self._showPopUpViewAnimated(animated: false)
        }
        return begin
    }
    
    override func continueTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        let continueTrack = super.continueTracking(touch, with: event)
        if continueTrack {

        }
        return continueTrack
    }
    
    override func cancelTracking(with event: UIEvent?) {
        super.cancelTracking(with: event)
        if self.popUpViewAlwaysOn! {
            self._hidePopUpViewAnimated(animated: true)
        }
    }
    
    override func endTracking(_ touch: UITouch?, with event: UIEvent?) {
        super.endTracking(touch, with: event)
        if !self.popUpViewAlwaysOn! {
            self._hidePopUpViewAnimated(animated: true)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

