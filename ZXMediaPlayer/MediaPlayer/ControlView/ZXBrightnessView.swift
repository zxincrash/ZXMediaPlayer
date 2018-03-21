//
//  ZXBrightnessView.swift
//  ZXValueTrackingSlider
//
//  Created by zhaoxin on 2017/11/23.
//  Copyright © 2017年 zhaoxin. All rights reserved.
//

import UIKit

@IBDesignable class ZXBrightnessView: UIView {

    /** 调用单例记录播放状态是否锁定屏幕方向*/
    var isLockScreen:Bool  = false
    
    /** 是否允许横屏,来控制只有竖屏的状态*/
    var isAllowLandscape:Bool = true
    {
        didSet{
            let window:UIWindow = UIApplication.shared.keyWindow!
            window.zx_currentViewController().setNeedsStatusBarAppearanceUpdate()
            
        }
    }
    
    var isStatusBarHidden:Bool = false{
        didSet{
            let window:UIWindow = UIApplication.shared.keyWindow!
            window.zx_currentViewController().setNeedsStatusBarAppearanceUpdate()

            
        }
    }
    
    /** 是否是横屏状态 */
    var isLandscape:Bool? = false{
        didSet{
            if isLandscape != nil {
                let window:UIWindow = UIApplication.shared.keyWindow!
                window.zx_currentViewController().setNeedsStatusBarAppearanceUpdate()
            }

        }
    }
    
    private var tipArray:NSMutableArray?
    private var orientationDidChange:Bool = false
    
    static private let shareBrightnessView:ZXBrightnessView = ZXBrightnessView()
    static public func shareInstance() -> ZXBrightnessView{
        UIApplication.shared.keyWindow?.addSubview(shareBrightnessView)
        
        return shareBrightnessView
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.frame = CGRect.init(x: SCREEN_WIDTH*0.5, y: SCREEN_HEIGHT*0.5, width: 155, height: 155)
        
        self.layer.cornerRadius  = 10
        self.layer.masksToBounds = true
        
        // 使用UIToolbar实现毛玻璃效果
        let toolBar:UIToolbar = UIToolbar.init(frame: self.bounds)
        toolBar.alpha = 0.97
        self.addSubview(toolBar)
        
        self.addSubview(self.backImage)
        self.addSubview(self.title)
        self.addSubview(self.longView)
        
        self.createTips()
        self.addNotification()
        self.addObserver()
        
        self.alpha = 0.0 
    }
    
    @IBInspectable lazy var backImage: UIImageView = {
        let backImg:UIImageView = UIImageView.init(frame: CGRect.init(x: 0, y: 0, width: 79, height: 76))
        backImg.image = ZXMediaPlayerImage("MediaPlayer_brightness")
        return backImg
    }()
    
    @IBInspectable lazy var title: UILabel = {
        let titleLab:UILabel = UILabel.init(frame: CGRect.init(x: 0, y: 5, width: self.bounds.size.width, height: 30))
        titleLab.font = UIFont.boldSystemFont(ofSize: 16)
        titleLab.textColor = RGBA(0.25, 0.22, 0.21, 1)
        titleLab.textAlignment = NSTextAlignment.center
        titleLab.text = "亮度"
        return titleLab
    }()

    @IBInspectable lazy var longView: UIView = {
        let longV:UIView = UIView.init(frame: CGRect.init(x: 13, y: 132, width: self.bounds.size.width - 26, height: 7))
        longV.backgroundColor = RGBA(0.25, 0.22, 0.21, 1)
        return longV
    }()

    // MARK: create Tips
    private func createTips(){
        self.tipArray = NSMutableArray.init(capacity: 16)
        
        let tipW:CGFloat = (self.longView.bounds.size.width - 17)/16
        let tipH:CGFloat = 5
        let tipY:CGFloat = 1
        
        for i in 0..<16 {
            let tipX:CGFloat = CGFloat(i) * (tipW + 1) + 1
            let image:UIImageView = UIImageView.init(frame: CGRect.init(x: tipX, y: tipY, width: tipW, height: tipH))
            image.backgroundColor = .white
            self.longView.addSubview(image)
            self.tipArray?.add(image)
            
        }
        self.updateLongView(sound: UIScreen.main.brightness)
    }
    
    //MARK: - Notification KVO
    private func addNotification(){
        NotificationCenter.default.addObserver(self, selector: #selector(updateLayer(notify:)), name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
    }
    
    private func addObserver(){
        UIScreen.main.addObserver(self, forKeyPath: "brightness", options: NSKeyValueObservingOptions.new, context: nil)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if let newValue = change?[NSKeyValueChangeKey.newKey] {
            self.appearSoundView()
            self.updateLongView(sound: newValue as! CGFloat)
        }else{
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
        
    }
    @objc private func updateLayer(notify:NSNotification){
        self.orientationDidChange = true
        self.setNeedsLayout()
        self.layoutIfNeeded()
    }
    
    //MARK: - Methond
    private func appearSoundView(){
        if self.alpha == 0 {
            self.orientationDidChange = false
            self.alpha = 1.0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.disAppearSoundView()
        }
    }
    
    private func disAppearSoundView(){
        if self.alpha == 1.0 {
            UIView.animate(withDuration: 0.8, animations: {
                self.alpha = 0.0
            })
        }
    }
    
    //MARK: - Update View
    private func updateLongView(sound:CGFloat) {
        let stage:CGFloat = 1/15
        let level:Int = Int(sound/stage)
        
        let array:Array<UIImageView> = self.tipArray as! Array
        
        for i in 0..<array.count  {
            let img:UIImageView = array[i]
            if i <= level{
                img.isHidden = false
            }else{
                img.isHidden = true
            }
            
        }
        
        
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.backImage.center = CGPoint.init(x: 155*0.5, y: 155*0.5)
        self.center = CGPoint.init(x: SCREEN_WIDTH*0.5, y: SCREEN_HEIGHT*0.5)
    }
    
    deinit {
        UIScreen.main.removeObserver(self, forKeyPath: "brightness")
        NotificationCenter.default.removeObserver(self)

    }

    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
