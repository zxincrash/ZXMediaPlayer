//
//  ZXMediaControlView.swift
//  ZXMediaPlayer (https://github.com/zxin2928/ZXMediaPlayer)
//
//  Created by zhaoxin on 2017/11/24.
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
import ZXLoadingView
import SnapKit

let  MediaPlayerAnimationTimeInterval:CGFloat = 7.0
let  MediaPlayerControlBarAutoFadeOutTimeInterval:CGFloat = 0.35


protocol ZXMediaControlViewDelegate {
    func playAction(_ controlView:ZXMediaControlView, button:UIButton)
    func progressSliderTouchBegan(_ controlView:ZXMediaControlView, slide:ZXValueTrackingSlider)
    func progressSliderValueChanged(_ controlView:ZXMediaControlView, slide:ZXValueTrackingSlider)
    func progressSliderTouchEnded(_ controlView:ZXMediaControlView, slide:ZXValueTrackingSlider)
    
    func progressSliderTap(_ controlView:ZXMediaControlView, slideValue:CGFloat)
    
    func fullScreenAction(_ controlView:ZXMediaControlView, button:UIButton)
    func lockScreenAction(_ controlView:ZXMediaControlView, button:UIButton)
    func closeAction(_ controlView:ZXMediaControlView, button:UIButton)
    func backAction(_ controlView:ZXMediaControlView, button:UIButton)
    func repeatPlayAction(_ controlView:ZXMediaControlView,button:UIButton)
    func downloadVideoAction(_ controlView:ZXMediaControlView, button:UIButton)
    
    func centerPlayAction(_ controlView:ZXMediaControlView, button:UIButton)
    func failAction(_ controlView:ZXMediaControlView, button:UIButton)
    
    func resolutionAction(button:UIButton)
}

class ZXMediaControlView: UIView,UIGestureRecognizerDelegate {
    var delegate: ZXMediaControlViewDelegate?

    var showing:Bool = false
    var isCellVideo:Bool = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.addSubview(self.placeholderImageView)
        self.addSubview(self.topImageView)
        self.addSubview(self.bottomImageView)
        
        self.bottomImageView.addSubview(self.startBtn)
        self.bottomImageView.addSubview(self.currentTimeLabel)
        self.bottomImageView.addSubview(self.progressView)
        self.bottomImageView.addSubview(self.videoSlider)
        self.bottomImageView.addSubview(self.fullScreenBtn)
        self.bottomImageView.addSubview(self.totalTimeLabel)
        
        self.topImageView.addSubview(self.downLoadBtn)
        self.addSubview(self.lockBtn)
        self.topImageView.addSubview(self.backBtn)
        self.addSubview(self.activity)
        self.addSubview(self.repeatBtn)
        self.addSubview(self.playeBtn)
        self.addSubview(self.failBtn)
        
        self.addSubview(self.fastView)
        self.fastView.addSubview(self.fastImageView)
        self.fastView.addSubview(self.fastTimeLabel)
        self.fastView.addSubview(self.fastProgressView)
        
        self.topImageView.addSubview(self.resolutionBtn)
        self.topImageView.addSubview(self.titleLabel)
        self.addSubview(self.closeBtn)
        self.addSubview(self.bottomProgressView)

        // 添加子控件的约束
        self.makeSubViewsConstraints()
        
        self.downLoadBtn.isHidden = true
        self.resolutionBtn.isHidden = true
        // 初始化时重置controlView
        self.zx_playerResetControlView()
        // app退到后台
        NotificationCenter.default.addObserver(self, selector: #selector(appDidEnterBackground), name: Notification.Name.UIApplicationWillResignActive, object: nil)
        // app进入前台
        NotificationCenter.default.addObserver(self, selector: #selector(appDidEnterPlayground), name: Notification.Name.UIApplicationDidBecomeActive, object: nil)
        
        self.listeningRotating()
        self.onDeviceOrientationChange()
    }
    
    func makeSubViewsConstraints(){
        self.layoutIfNeeded()
        self.placeholderImageView.snp.makeConstraints { (make) in
            make.edges.equalTo(self)
        }

        self.closeBtn.snp.makeConstraints { (make) in
            make.trailing.equalTo(self.snp.trailing).offset(7)
            make.top.equalTo(self.snp.top).offset(-7)
            make.width.height.equalTo(20)
        }
        
        self.topImageView.snp.makeConstraints { (make) in
            make.leading.trailing.equalTo(self)
            make.top.equalTo(self.snp.top).offset(0)
            make.height.equalTo(50)
        }
        self.backBtn.snp.makeConstraints { (make) in
            make.leading.equalTo(self.topImageView.snp.leading).offset(10)
            make.top.equalTo(self.topImageView.snp.top).offset(3)
            make.width.height.equalTo(40)
        }
        
        self.downLoadBtn.snp.makeConstraints { (make) in
            make.width.equalTo(40)
            make.height.equalTo(49)
            make.trailing.equalTo(self.topImageView.snp.trailing).offset(-10)
            make.centerY.equalTo(self.backBtn.snp.centerY)
        }
        self.resolutionBtn.snp.makeConstraints { (make) in
            make.width.equalTo(40)
            make.height.equalTo(25)
            make.trailing.equalTo(self.downLoadBtn.snp.leading).offset(-10)
            make.centerY.equalTo(self.backBtn.snp.centerY)
        }

        self.titleLabel.snp.makeConstraints { (make) in
            make.leading.equalTo(self.backBtn.snp.trailing).offset(5)
            make.centerY.equalTo(self.backBtn.snp.centerY)
            make.trailing.equalTo(self.resolutionBtn.snp.leading).offset(-10)
        }
        
        self.bottomImageView.snp.makeConstraints { (make) in
            make.leading.trailing.bottom.equalTo(self)
            make.height.equalTo(50)
        }

        self.startBtn.snp.makeConstraints { (make) in
            make.leading.equalTo(self.bottomImageView.snp.leading).offset(5)
            make.bottom.equalTo(self.bottomImageView.snp.bottom).offset(-5)
            make.width.height.equalTo(30)
        }
        
        self.currentTimeLabel.snp.makeConstraints { (make) in
            make.leading.equalTo(self.startBtn.snp.trailing).offset(-3)
            make.centerY.equalTo(self.startBtn.snp.centerY)
            make.width.equalTo(43)
        }
        
        self.fullScreenBtn.snp.makeConstraints { (make) in
            make.width.height.equalTo(30)
            make.trailing.equalTo(self.bottomImageView.snp.trailing).offset(-5)
            make.centerY.equalTo(self.startBtn.snp.centerY)
        }
        
        self.totalTimeLabel.snp.makeConstraints { (make) in
            make.trailing.equalTo(self.fullScreenBtn.snp.leading).offset(3)
            make.centerY.equalTo(self.startBtn.snp.centerY)
            make.width.equalTo(43)
        }
        
        self.progressView.snp.makeConstraints { (make) in
            make.leading.equalTo(self.currentTimeLabel.snp.trailing).offset(4)
            make.trailing.equalTo(self.totalTimeLabel.snp.leading).offset(-4)
            make.centerY.equalTo(self.startBtn.snp.centerY)
        }
        
        self.videoSlider.snp.makeConstraints { (make) in
            make.leading.equalTo(self.currentTimeLabel.snp.trailing).offset(4)
            make.trailing.equalTo(self.totalTimeLabel.snp.leading).offset(-4)
            make.centerY.equalTo(self.currentTimeLabel.snp.centerY).offset(-1)
            make.height.equalTo(30)
        }

        self.lockBtn.snp.makeConstraints { (make) in
            make.leading.equalTo(self.snp.leading).offset(15)
            make.centerY.equalTo(self.snp.centerY)
            make.width.height.equalTo(32)
        }
        
        self.repeatBtn.snp.makeConstraints { (make) in
            make.center.equalTo(self)
        }
        
        self.playeBtn.snp.makeConstraints { (make) in
            make.width.height.equalTo(50)
            make.center.equalTo(self)
        }
        
        self.activity.snp.makeConstraints { (make) in
            make.center.equalTo(self)
            make.width.height.equalTo(45)
        }
        
        self.failBtn.snp.makeConstraints { (make) in
            make.center.equalTo(self)
            make.width.equalTo(130)
            make.height.equalTo(33)
        }
        
        self.fastView.snp.makeConstraints { (make) in
            make.width.equalTo(125)
            make.height.equalTo(80)
            make.center.equalTo(self)
        }
        self.fastImageView.snp.makeConstraints { (make) in
            make.width.height.equalTo(32)
            make.top.equalTo(5)
            make.centerX.equalTo(self.fastView.snp.centerX)
        }
        
        self.fastTimeLabel.snp.makeConstraints { (make) in
            make.leading.trailing.equalTo(0)
            make.top.equalTo(self.fastImageView.snp.bottom).offset(2)
        }
        
        self.fastProgressView.snp.makeConstraints { (make) in
            make.leading.equalTo(12)
            make.trailing.equalTo(-12)
            make.top.equalTo(self.fastTimeLabel.snp.bottom).offset(10)
        }

        self.bottomProgressView.snp.makeConstraints { (make) in
            make.leading.trailing.equalTo(self)
            make.bottom.equalTo(self)
        }
        
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        self.layoutIfNeeded()
        self.zx_playerCancelAutoFadeOutControlView()
        if !self.shrink && !self.playeEnd {
            self.zx_playerShowControlView()
        }
        
        let currentOrientation = UIApplication.shared.statusBarOrientation
        if currentOrientation == .portrait {
            self.setOrientationPortraitConstraint()
        }else{
            self.setOrientationLandscapeConstraint()
        }
    }
    
    //MARK: - action
    @objc private func playBtnClick(sender:UIButton){
        sender.isSelected = !sender.isSelected;
        
        delegate?.playAction(self, button: sender)

    }
    
    @objc private func progressSliderTouchBegan(sender:ZXValueTrackingSlider){
        sender.isSelected = !sender.isSelected;
        self.zx_playerCancelAutoFadeOutControlView()
        self.videoSlider.popUpView?.isHidden = true
        delegate?.progressSliderTouchBegan(self, slide: sender)
        
    }
    @objc private func progressSliderValueChanged(sender:ZXValueTrackingSlider){
        delegate?.progressSliderValueChanged(self, slide: sender)
        
    }
    @objc private func progressSliderTouchEnded(sender:ZXValueTrackingSlider){
        self.showing = true
        delegate?.progressSliderTouchEnded(self, slide: sender)
    }

    @objc private func tapSlideAction(tap:UITapGestureRecognizer){
        if (tap.view?.isKind(of: UISlider.self))! {
            let slide = tap.view as? UISlider
            let point:CGPoint = tap.location(in: slide)
            let length:CGFloat = slide!.frame.size.width
            
            let tapValue:CGFloat = point.x/length
            delegate?.progressSliderTap(self, slideValue: tapValue)
            
        }
    }
    
    // 不做处理，只是为了滑动slider其他地方不响应其他手势
    @objc private func panRecognizer(sender:UIPanGestureRecognizer){}
    
    @objc private func fullScreenBtnClick(sender:UIButton){
        sender.isSelected = !sender.isSelected
        delegate?.fullScreenAction(self, button: sender)
    }

    @objc private func lockScreenBtnClick(sender:UIButton){
        sender.isSelected = !sender.isSelected
        self.showing = false
        self.zx_playerShowControlView()
        delegate?.lockScreenAction(self, button: sender)
    }
    
    @objc private func backBtnClick(sender:UIButton){
        // 状态条的方向旋转的方向,来判断当前屏幕的方向
        let orientation:UIInterfaceOrientation = UIApplication.shared.statusBarOrientation
        // 在cell上并且是竖屏时候响应关闭事件
        if self.isCellVideo && orientation == UIInterfaceOrientation.portrait {
            delegate?.closeAction(self, button: sender)
        }else{
            delegate?.backAction(self, button: sender)
        }

    }
    
    @objc private func closeBtnClick(sender:UIButton){
        delegate?.closeAction(self, button: sender)
    }
    
    @objc private func repeatBtnClick(sender:UIButton){
        self.zx_playerResetControlView()
        self.zx_playerShowControlView()
        delegate?.repeatPlayAction(self, button: sender)
    }
    
    @objc private func downLoadBtnClick(sender:UIButton){
        delegate?.downloadVideoAction(self, button: sender)
    }
    
    @objc private func resolutionBtnClick(sender:UIButton){
        sender.isSelected = !sender.isSelected
        self.resolutionView.isHidden = !sender.isSelected
    }
    
    @objc private func centerPlayBtnClick(sender:UIButton){
        delegate?.centerPlayAction(self, button: sender)
    }
    
    @objc private func failBtnClick(sender:UIButton){
        self.failBtn.isHidden = true
        delegate?.failAction(self, button: sender)
    }
    
    /**
     *  点击切换分别率按钮
     */
    @objc func changeResolution(sender:UIButton){
        sender.isSelected = true
        if sender.isSelected {
            sender.backgroundColor = RGBA(86, 143, 232, 1)
        }else{
            sender.backgroundColor = UIColor.clear
        }
        self.resoultionCurrentBtn.isSelected = false
        self.resoultionCurrentBtn.backgroundColor = UIColor.clear
        self.resoultionCurrentBtn = sender
        
        self.resolutionView.isHidden = true
        self.resolutionBtn.isSelected = false
        self.resolutionBtn.setTitle(sender.titleLabel?.text, for: .normal)
        delegate?.resolutionAction(button: sender)
    }
    
    //MARK: - 前后台切换
    /**
     *  应用退到后台
     */
    @objc func appDidEnterBackground(){
        self.zx_playerCancelAutoFadeOutControlView()
    }
    
    /**
     *  应用进入前台
     */
    @objc func appDidEnterPlayground(){
        if !self.shrink {
            self.zx_playerShowControlView()
        }
    }
    
    func playerPlayDidEnd(){
        self.backgroundColor = RGBA(0, 0, 0, 0.6)
        self.repeatBtn.isHidden = false
        self.showing = false
        self.zx_playerShowControlView()
    }
    
    //MARK: - 旋转屏幕处理
    /**
     *  屏幕方向发生变化会调用这里
     */
    @objc func onDeviceOrientationChange(){
        if ZXBrightnessShared.isLockScreen {
            return
        }
        self.lockBtn.isHidden = !self.fullScreen
        self.fullScreenBtn.isSelected = self.fullScreen
        let orientation:UIDeviceOrientation = UIDevice.current.orientation
        if orientation == UIDeviceOrientation.faceUp || orientation == UIDeviceOrientation.faceDown || orientation == UIDeviceOrientation.unknown || orientation == UIDeviceOrientation.portraitUpsideDown {
            return
        }
        if MediaPlayerOrientationIsLandscape {
            self.setOrientationLandscapeConstraint()
        }else{
            self.setOrientationPortraitConstraint()
        }
        self.layoutIfNeeded()
    }
    
    func setOrientationLandscapeConstraint(){
        if self.isCellVideo {
            self.shrink = false
        }
        self.fullScreen = true
        self.lockBtn.isHidden = !self.fullScreen
        self.backBtn.setImage(ZXMediaPlayerImage("MediaPlayer_back_full"), for: .normal)
        self.layoutIfNeeded()
        self.backBtn.snp.makeConstraints { (make) in
            make.top.equalTo(self.topImageView.snp.top).offset(23)
            make.leading.equalTo(self.topImageView.snp.leading).offset(10)
            make.width.height.equalTo(40)
        }
    }

    /**
     *  设置竖屏的约束
     */
    func setOrientationPortraitConstraint(){
        self.fullScreen = false
        self.lockBtn.isHidden = !self.fullScreen
        self.fullScreenBtn.isSelected = self.fullScreen
        self.layoutIfNeeded()
        self.backBtn.snp.makeConstraints { (make) in
            make.leading.equalTo(self.topImageView.snp.leading).offset(10)
            make.top.equalTo(self.topImageView.snp.top).offset(10)
            make.width.height.equalTo(40)
        }
        if self.isCellVideo {
            self.backBtn.setImage(ZXMediaPlayerImage("MediaPlayer_close"), for: .normal)
        }
    }
    
    //MARK: - Private Method
    private func showControlView(){
        if self.lockBtn.isSelected {
            self.topImageView.alpha = 0
            self.bottomImageView.alpha = 0
        }else{
            self.topImageView.alpha = 1
            self.bottomImageView.alpha = 1
        }
        self.backgroundColor = RGBA(0, 0, 0, 0.3)
        self.lockBtn.alpha = 1
        if self.isCellVideo {
            self.shrink = false
        }
        self.bottomProgressView.alpha = 0
    }
    
    private func hideControlView(){
        self.backgroundColor = RGBA(0, 0, 0, 0)
        self.topImageView.alpha = self.playeEnd ? 1:0
        self.bottomImageView.alpha = 0
        self.lockBtn.alpha = 0
        self.bottomProgressView.alpha = 1

        self.resolutionBtn.isSelected = true
        self.resolutionBtnClick(sender: self.resolutionBtn)
        if self.fullScreen && !self.playeEnd && !self.shrink {
            ZXBrightnessShared.isStatusBarHidden = true

        }
    }

    //监听设备旋转通知
    private func listeningRotating(){
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        NotificationCenter.default.addObserver(self, selector: #selector(onDeviceOrientationChange), name: NSNotification.Name.UIScreenModeDidChange, object: nil)
    }

    private func autoFadeOutControlView(){
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(zx_playerHideControlView), object: nil)
        self.perform(#selector(zx_playerHideControlView) , with: nil, afterDelay: TimeInterval(MediaPlayerAnimationTimeInterval))
    }

    
    /**
     slider滑块的bounds
     */
    func thumbRect() -> CGRect{
        return self.videoSlider.thumbRect(forBounds: self.videoSlider.bounds, trackRect: self.videoSlider.trackRect(forBounds: self.videoSlider.bounds), value: self.videoSlider.value)
    }

    //MARK: - lazy(控制ui初始化)
    /** 标题 */
    lazy var titleLabel: UILabel = {
        let titleLab:UILabel = UILabel()
        titleLab.textColor = .white
        titleLab.font = UIFont.systemFont(ofSize: 15)
        return titleLab
    }()
    lazy var startBtn: UIButton = {
        let button:UIButton = UIButton.init(type: .custom)
        button.setImage(ZXMediaPlayerImage("MediaPlayer_play"), for: .normal)
        button.setImage(ZXMediaPlayerImage("MediaPlayer_pause"), for: .selected)
        button.addTarget(self, action: #selector(playBtnClick(sender:)), for: .touchUpInside)
        return button
    }()
    
    lazy var currentTimeLabel: UILabel = {
        let label:UILabel = UILabel()
        label.textColor = UIColor.white
        label.font = UIFont.systemFont(ofSize: 12)
        label.textAlignment = NSTextAlignment.center
        return label
    }()
    
    lazy var totalTimeLabel: UILabel = {
        let label:UILabel = UILabel()
        label.textColor = UIColor.white
        label.font = UIFont.systemFont(ofSize: 12)
        label.textAlignment = NSTextAlignment.center
        return label
    }()
    
    lazy var progressView: UIProgressView = {
        let progressV:UIProgressView = UIProgressView.init(progressViewStyle: UIProgressViewStyle.default)
        progressV.progressTintColor = RGBA(1, 1, 1, 0.5)
        progressV.trackTintColor = UIColor.lightGray
        return progressV
    }()
    
    lazy var videoSlider: ZXValueTrackingSlider = {
        let slide:ZXValueTrackingSlider = ZXValueTrackingSlider.init(frame: self.bounds)
        slide.popUpViewCornerRadious = 0.0
        slide.popUpViewColor = RGBA(19, 19, 9, 1)
        slide.popUpViewArrowLength = 8
        
        slide.setThumbImage(ZXMediaPlayerImage("MediaPlayer_slider"), for: .normal)
        slide.maximumValue = 1
        slide.minimumTrackTintColor = UIColor.white
        slide.maximumTrackTintColor = RGBA(0.5, 0.5, 0.5, 0.5)

        // slider开始滑动事件
        slide.addTarget(self, action: #selector(progressSliderTouchBegan(sender:)), for: .touchDown)
        // slider滑动中事件
        slide.addTarget(self, action: #selector(progressSliderValueChanged(sender:)), for: .valueChanged)
        // slider结束滑动事件
        slide.addTarget(self, action: #selector(progressSliderTouchEnded(sender:)), for: UIControlEvents.touchUpInside)
        slide.addTarget(self, action: #selector(progressSliderTouchEnded(sender:)), for: UIControlEvents.touchCancel)
        slide.addTarget(self, action: #selector(progressSliderTouchEnded(sender:)), for:UIControlEvents.touchUpOutside)

        let slideTap:UITapGestureRecognizer = UITapGestureRecognizer.init(target: self, action: #selector(tapSlideAction(tap:)))
        slide.addGestureRecognizer(slideTap)
        
        let panRecognizer:UIPanGestureRecognizer = UIPanGestureRecognizer.init(target: self, action: #selector(panRecognizer(sender:)))
        panRecognizer.delegate = self
        panRecognizer.maximumNumberOfTouches = 1
        panRecognizer.delaysTouchesBegan = true
        panRecognizer.delaysTouchesEnded = true
        panRecognizer.cancelsTouchesInView = true
        slide.addGestureRecognizer(panRecognizer)
        
        return slide
    }()
    
    lazy var fullScreenBtn: UIButton = {
        let button:UIButton = UIButton.init(type: .custom)
        button.setImage(ZXMediaPlayerImage("MediaPlayer_fullscreen"), for: .normal)
        button.setImage(ZXMediaPlayerImage("MediaPlayer_shrinkscreen"), for: .selected)
        button.addTarget(self, action: #selector(fullScreenBtnClick(sender:)), for: .touchUpInside)
        return button
    }()
    
    lazy var lockBtn: UIButton = {
        let button:UIButton = UIButton.init(type: .custom)
        button.setImage(ZXMediaPlayerImage("MediaPlayer_unlock-nor"), for: .normal)
        button.setImage(ZXMediaPlayerImage("MediaPlayer_lock-nor"), for: .selected)
        button.addTarget(self, action: #selector(lockScreenBtnClick(sender:)), for: .touchUpInside)
        return button
    }()
    
    lazy var activity: ZXLoadingView = {
        let loadingView:ZXLoadingView = ZXLoadingView()
        loadingView.lineWidth = 1
        loadingView.duration  = 1
        loadingView.tintColor = UIColor.white.withAlphaComponent(0.9)
        return loadingView
    }()
    
    lazy var backBtn: UIButton = {
        let button:UIButton = UIButton.init(type: .custom)
        button.setImage(ZXMediaPlayerImage("MediaPlayer_back_full"), for: .normal)
        button.addTarget(self, action: #selector(backBtnClick(sender:)), for: .touchUpInside)
        return button
    }()

    lazy var closeBtn: UIButton = {
        let button:UIButton = UIButton.init(type: .custom)
        button.setImage(ZXMediaPlayerImage("MediaPlayer_close"), for: .normal)
        button.addTarget(self, action: #selector(closeBtnClick(sender:)), for: .touchUpInside)
        return button
    }()
    
    lazy var repeatBtn: UIButton = {
        let button:UIButton = UIButton.init(type: .custom)
        button.setImage(ZXMediaPlayerImage("MediaPlayer_repeat_video"), for: .normal)
        button.addTarget(self, action: #selector(repeatBtnClick(sender:)), for: .touchUpInside)
        return button
    }()

    lazy var bottomImageView:UIImageView = {
        let view:UIImageView = UIImageView()
        view.isUserInteractionEnabled = true
        view.image = ZXMediaPlayerImage("MediaPlayer_bottom_shadow")
        return view
    }()
    
    lazy var topImageView:UIImageView = {
        let view:UIImageView = UIImageView()
        view.isUserInteractionEnabled = true
        view.image = ZXMediaPlayerImage("MediaPlayer_top_shadow")
        return view
    }()

    lazy var downLoadBtn: UIButton = {
        let button:UIButton = UIButton.init(type: .custom)
        button.setImage(ZXMediaPlayerImage("MediaPlayer_download"), for: .normal)
        button.setImage(ZXMediaPlayerImage("MediaPlayer_not_download"), for: .disabled)
        button.addTarget(self, action: #selector(downLoadBtnClick(sender:)), for: .touchUpInside)
        return button
    }()
    
    lazy var resolutionBtn: UIButton = {
        let button:UIButton = UIButton.init(type: .custom)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 12)
        button.backgroundColor = RGBA(0, 0, 0, 0.7)
        button.addTarget(self, action: #selector(resolutionBtnClick(sender:)), for: .touchUpInside)
        return button
    }()
    
    lazy var resolutionView:UIView = UIView.init()
    
    lazy var playeBtn: UIButton = {
        let button:UIButton = UIButton.init(type: .custom)
        button.setImage(ZXMediaPlayerImage("MediaPlayer_play_btn"), for: .normal)
        button.addTarget(self, action: #selector(centerPlayBtnClick(sender:)), for: .touchUpInside)
        return button
    }()
    
    lazy var failBtn: UIButton = {
        let button:UIButton = UIButton.init(type: .custom)
        button.setTitle("加载失败，点击重试", for: .normal)
        button.setTitleColor(UIColor.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        button.backgroundColor = RGBA(0, 0, 0, 0.7)
        button.addTarget(self, action: #selector(failBtnClick(sender:)), for: .touchUpInside)
        return button
    }()
    
    /** 快进快退View*/
    lazy var fastView: UIView = {
        let view:UIView = UIView()
        view.backgroundColor = RGBA(0, 0, 0, 0.8)
        view.layer.cornerRadius = 4
        view.clipsToBounds = true
        return view
    }()
    
    /** 快进快退进度progress*/
    lazy var fastProgressView: UIProgressView = {
        let progressV:UIProgressView = UIProgressView()
        progressV.progressTintColor = UIColor.white
        progressV.trackTintColor = UIColor.lightGray.withAlphaComponent(0.4)
        return progressV
    }()
    
    /** 快进快退时间*/
    lazy var fastTimeLabel: UILabel = {
        let label:UILabel = UILabel()
        label.textColor = UIColor.white
        label.textAlignment = NSTextAlignment.center
        label.font = UIFont.systemFont(ofSize: 14)
        return label
    }()
    
    /** 快进快退ImageView*/
    lazy var fastImageView: UIImageView = {
        let view:UIImageView = UIImageView()
        return view
        
    }()
    
    /** 当前选中的分辨率btn按钮 */
    var resoultionCurrentBtn: UIButton!
    
    /** 占位图 */
    lazy var placeholderImageView:UIImageView = {
        let view:UIImageView = UIImageView()
        view.isUserInteractionEnabled = true
        return view
    }()
    
    /** 控制层消失时候在底部显示的播放进度progress */
    lazy var bottomProgressView: UIProgressView = {
        let progressV:UIProgressView = UIProgressView()
        progressV.progressTintColor = UIColor.white
        progressV.trackTintColor = UIColor.clear
        return progressV
    }()
    
    /** 分辨率的名称 */
    var resolutionArray:Array<String>?
    
    /** 小屏播放 */
    var shrink:Bool = false{
        didSet{
            self.closeBtn.isHidden = !shrink
            self.bottomProgressView.isHidden = shrink
        }
    }
    
    /** 是否拖拽slider控制播放进度 */
    var dragged:Bool = false
    /** 是否播放结束 */
    var playeEnd:Bool = false
    /** 是否全屏播放 */
    var fullScreen:Bool = false

    //MARK: - UIGestureRecognizerDelegate
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        let rect:CGRect = self.thumbRect()
        let point:CGPoint = touch.location(in: self.videoSlider)
        if (touch.view?.isKind(of: UISlider.self))! {
            if point.x <= rect.origin.x + rect.size.width && point.x >= rect.origin.x{
                return false
            }
        }
        return true
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        UIDevice.current.endGeneratingDeviceOrientationNotifications()
    }
}

//MARK: - Public method
extension ZXMediaControlView{
    /** 重置ControlView */
    public func zx_playerResetControlView(){
        self.activity.stopAnimating()
        self.videoSlider.value = 0
        self.bottomProgressView.progress = 0
        self.progressView.progress = 0
        self.currentTimeLabel.text = "00:00"
        self.totalTimeLabel.text = "00:00"
        self.fastView.isHidden = true
        self.repeatBtn.isHidden = true
        self.playeBtn.isHidden = true
        self.resolutionView.isHidden = true
        self.failBtn.isHidden = true
        self.backgroundColor = UIColor.clear
        self.downLoadBtn.isEnabled = true
        self.shrink = false
        self.showing = true
        self.playeEnd = false
        self.lockBtn.isHidden = !self.fullScreen
        self.placeholderImageView.alpha = 1
    }
    
    public func zx_playerResetControlViewForResolution(){
        self.fastView.isHidden = true
        self.repeatBtn.isHidden = true
        self.resolutionView.isHidden = true
        self.playeBtn.isHidden = true
        self.downLoadBtn.isEnabled = true
        self.failBtn.isHidden = true
        self.backgroundColor = UIColor.clear
        self.shrink = false
        self.showing = false
        self.playeEnd = false
    }
    
    
    /**
     *  取消延时隐藏controlView的方法
     */
    public func zx_playerCancelAutoFadeOutControlView(){
        self.showing = false
        NSObject.cancelPreviousPerformRequests(withTarget: self)
    }
    
    /** 设置播放模型 */
    public func zx_playerModel(playerModel:MediaPlayerModel){
        if playerModel.title != nil {
            self.titleLabel.text = playerModel.title
        }
        if playerModel.placeholderImageURLString != nil {
            //            self.placeholderImageView.
        }else{
            self.placeholderImageView.image = playerModel.placeholderImage
        }
        
        if playerModel.resolutionDic != nil {
            self.zx_playerResolutionArray(resolutionArray: playerModel.resolutionDic.allKeys as! Array<String>)
        }
    }
    
    /** 正在播放（隐藏placeholderImageView） */
    public func zx_playerItemPlaying(){
        UIView.animate(withDuration: 1) {
            self.placeholderImageView.alpha = 0
        }
    }
    
    /**
     *  show controlView
     */
    
    public func zx_playerShowControlView(){
        if self.showing {
            self.zx_playerHideControlView()
            return
        }
        self.zx_playerCancelAutoFadeOutControlView()
        UIView.animate(withDuration: TimeInterval(MediaPlayerControlBarAutoFadeOutTimeInterval), animations: {
            self.showControlView()
        }, completion: { (finished) in
            self.showing = true
            self.autoFadeOutControlView()
        })
    }
    
    /**
     *  隐藏控制层
     */
    @objc public func zx_playerHideControlView(){
        if !self.showing {
            return
        }
        self.zx_playerCancelAutoFadeOutControlView()
        UIView.animate(withDuration: TimeInterval(MediaPlayerControlBarAutoFadeOutTimeInterval), animations: {
            self.hideControlView()
        }, completion: { (finished) in
            self.showing = false
        })
    }
    
    /** 小屏播放 */
    public func zx_playerBottomShrinkPlay(){
        self.updateConstraints()
        self.layoutIfNeeded()
        self.shrink = true
        self.hideControlView()
    }
    
    /** 在cell播放 */
    public func zx_playerCellPlay(){
        self.isCellVideo = true
        self.shrink = true
        self.backBtn.setImage(ZXMediaPlayerImage("MediaPlayer_close"), for: .normal)
        self.layoutIfNeeded()
        self.zx_playerShowControlView()
    }
    
    public func zx_playerCurrentTime(currentTime:Int, totalTime:Int, value:CGFloat){
        //caculate the current progress
        let proMin:Int = currentTime/60
        let proSec:Int = currentTime%60
        
        //duration 总时长
        let durMin:Int = totalTime/60
        let durSec:Int = totalTime%60
        if !self.dragged {
            self.videoSlider.value = Float(value)
            self.bottomProgressView.progress = Float(value)
            self.currentTimeLabel.text = String.init(format: "%02zd:%02zd", proMin,proSec)
        }
        self.totalTimeLabel.text = String.init(format: "%02zd:%02zd", durMin,durSec)
        
    }
    
    public func zx_playerDraggedTime(draggedTime:Int, totalTime:Int, isForward:Bool, hasPreView:Bool){
        self.activity.stopAnimating()
        //caculate the current progress
        let proMin:Int = draggedTime/60
        let proSec:Int = draggedTime%60
        
        //duration 总时长
        let durMin:Int = totalTime/60
        let durSec:Int = totalTime%60
        let currentTimeStr:String = String.init(format: "%02zd:%02zd", proMin,proSec)
        let totalTimeStr:String = String.init(format: "%02zd:%02zd", durMin,durSec)
        let draggedValue:CGFloat = CGFloat(draggedTime)/CGFloat(totalTime)
        let timeStr:String = String.init(format: "%@ / %@", currentTimeStr,totalTimeStr)
        //显示 隐藏预览窗
        self.videoSlider.popUpView?.isHidden = !hasPreView
        self.videoSlider.setValue(Float(draggedValue), animated: false)
        self.bottomProgressView.progress = Float(draggedValue)
        self.currentTimeLabel.text = currentTimeStr
        self.dragged = true
        
        if isForward {
            self.fastImageView.image = ZXMediaPlayerImage("MediaPlayer_fast_forward")
        }else{
            self.fastImageView.image = ZXMediaPlayerImage("MediaPlayer_fast_backward")
        }
        self.fastView.isHidden = hasPreView
        self.fastTimeLabel.text = timeStr
        self.fastProgressView.progress = Float(draggedValue)
    }
    
    public func zx_playerDraggedEnd(){
        DispatchQueue.main.asyncAfter(deadline: .now()+1) {
            self.fastView.isHidden = true
        }
        
        self.dragged = false
        // 结束滑动时候把开始播放按钮改为播放状态
        self.startBtn.isSelected = true
        // 滑动结束延时隐藏controlView
        self.autoFadeOutControlView()
    }
    
    public func zx_playerDraggedTime(draggedTime:Int, slideImage:UIImage){
        let proMin:Int = draggedTime/60
        let proSec:Int = draggedTime%60
        let currentTimeStr:String = String.init(format: "%02zd:%02zd", proMin,proSec)
        self.videoSlider.preImage = slideImage
        self.videoSlider.preText = currentTimeStr
        self.fastView.isHidden = true
    }
    
    /** progress显示缓冲进度 */
    public func zx_playerSetProgress(progress:CGFloat){
        self.progressView.setProgress(Float(progress), animated: false)
    }
    
    /** 视频加载失败 */
    public func zx_playerItemStatusFailed(error:Error){
        self.failBtn.isHidden = false
    }
    
    /** 加载的菊花 */
    public func zx_playerActivity(animated:Bool){
        if animated {
            self.activity.startAnimating()
            self.fastView.isHidden = true
        }else{
            self.activity.stopAnimating()
        }
        
    }
    
    /** 播放完了 */
    public func zx_playerPlayEnd(){
        self.repeatBtn.isHidden = false
        self.playeEnd = true
        self.showing = false
        self.hideControlView()
        self.backgroundColor = RGBA(0, 0, 0, 0.3)
        ZXBrightnessShared.isStatusBarHidden = false
        self.bottomProgressView.alpha = 0
    }
    
    /**
     是否有下载功能
     */
    public func zx_playerHasDownloadFunction(sender:Bool){
        self.downLoadBtn.isHidden = !sender
    }
    
    /**
     是否有切换分辨率功能
     */
    public func zx_playerResolutionArray(resolutionArray:Array<String>){
        self.resolutionBtn.isHidden = false
        self.resolutionBtn.setTitle(resolutionArray.first, for: .normal)
        self.resolutionView = UIView()
        self.resolutionView.isHidden = true
        self.resolutionView.backgroundColor = RGBA(0, 0, 0, 0.7)
        self.addSubview(self.resolutionView)
        
        self.resolutionView.snp.makeConstraints { (make) in
            make.width.equalTo(40)
            make.height.equalTo(25*resolutionArray.count)
            make.leading.equalTo(self.resolutionBtn.snp.leading).offset(0)
            make.top.equalTo(self.resolutionBtn.snp.bottom).offset(0)
        }
        
        //分辨率view上的button
        for i in 0..<resolutionArray.count{
            let btn:UIButton = UIButton.init(type: .custom)
            btn.layer.borderColor = UIColor.white.cgColor
            btn.layer.borderWidth = 0.5
            btn.tag = 200+i
            btn.frame = CGRect.init(x: 0, y: 25*i, width: 40, height: 25)
            btn.titleLabel?.font = UIFont.systemFont(ofSize: 12)
            btn.setTitle(resolutionArray[i], for: .normal)
            if i == 0{
                self.resoultionCurrentBtn = btn
                btn.isSelected = true
                btn.backgroundColor = RGBA(86, 143, 232, 1)
            }
            self.resolutionView.addSubview(btn)
            btn.addTarget(self, action: #selector(changeResolution(sender:)), for: .touchUpInside)
        }
    }
    
    /** 播放按钮状态 */
    public func zx_playerPlayBtnState(state:Bool){
        self.startBtn.isSelected = state
    }
    
    /** 锁定屏幕方向按钮状态 */
    public func zx_playerLockBtnState(state:Bool){
        self.lockBtn.isSelected = state
    }
    
    /** 下载按钮状态 */
    public func zx_playerDownloadBtnState(state:Bool){
        self.downLoadBtn.isEnabled = state
    }
    
}

