//
//  ZXMediaPlayerView.swift
//  ZXMediaPlayer (https://github.com/zxin2928/ZXMediaPlayer)
//
//  Created by zhaoxin on 2017/11/26.
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
import AVFoundation
import SnapKit
import MediaPlayer

//MARK: - 全屏播放控制器
class ZXFullscreenPlayerViewController:UIViewController{
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return  UIInterfaceOrientationMask.landscapeRight
    }
        
    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation{
        return UIInterfaceOrientation.landscapeRight
    }
        
    override var prefersStatusBarHidden: Bool{
        return true
    }
    
}

//MARK: - MediaPlayerDelegate
protocol MediaPlayerDelegate{
    func zx_playerBackAction()
    func zx_playerDownload(url:String)
    func zx_playerMoreAction()

}

//MARK: - 播放器ZXMediaPlayerView
class ZXMediaPlayerView: UIView,UIGestureRecognizerDelegate,ZXMediaControlViewDelegate {
    //MARK: 播放器状态
    public enum PanDirection {
        case HorizontalMoved
        case VerticalMoved
    }
    
    public enum MediaPlayerState{
        case Failed     // 播放失败
        case Buffering  // 缓冲中
        case Playing    // 播放中
        case Stopped    // 停止播放
        case Pause       // 暂停播放
    }
    
    // playerLayer的填充模式（默认：等比例填充，直到一个维度到达区域边界）
    public enum MediaPlayerLayerGravity{
        case resize           // 非均匀模式。两个维度完全填充至整个视图区域
        case resizeAspect     // 等比例填充，直到一个维度到达区域边界
        case resizeAspectFill // 等比例填充，直到填充满整个视图区域，其中一个维度的部分区域会被裁剪
    }
    
    //设置播放器的控制界面
    var controlView:ZXMediaControlView?{
        didSet{
            if controlView != nil {
                controlView?.delegate = self
                self.layoutIfNeeded()
                self.addSubview(controlView!)
                controlView?.snp.makeConstraints({ (make) in
                    make.edges.equalToSuperview()
                })
            }
        }

    }

    //MARK: private property
    /** 播放属性 */
    var player:AVPlayer?
    var playerItem:AVPlayerItem?{
        didSet{
            if playerItem != nil {
                NotificationCenter.default.addObserver(self, selector: #selector(moviePlayDidEnd(notification:)), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: playerItem)
                playerItem?.addObserver(self, forKeyPath: "status", options: NSKeyValueObservingOptions.new, context: nil)
                playerItem?.addObserver(self, forKeyPath: "loadedTimeRanges", options: NSKeyValueObservingOptions.new, context: nil)
                // 缓冲区空了，需要等待数据
                playerItem?.addObserver(self, forKeyPath: "playbackBufferEmpty", options: NSKeyValueObservingOptions.new, context: nil)
                // 缓冲区有足够数据可以播放了
                playerItem?.addObserver(self, forKeyPath: "playbackLikelyToKeepUp", options: NSKeyValueObservingOptions.new, context: nil)

            }
        }
    }
    var urlAsset:AVURLAsset?
    lazy var imageGenerator: AVAssetImageGenerator = {
        let generator = AVAssetImageGenerator.init(asset: self.urlAsset!)
        return generator
    }()
    
    /** playerLayer */
    var playerLayer:AVPlayerLayer?
    var timeObserve:Any?
    /** 滑杆 */
    var volumeViewSlider:UISlider?
    /** 用来保存快进的总时长 */
    var sumTime:CGFloat = 0
    /** 定义一个实例变量，保存枚举值 */
    var panDirection:PanDirection?
    /** 播发器的几种状态 */
    var state:MediaPlayerState?{
        didSet{
            // 控制菊花显示、隐藏
            self.controlView?.zx_playerActivity(animated: state == MediaPlayerState.Buffering)
            if state == MediaPlayerState.Playing || state == MediaPlayerState.Buffering {
                self.controlView?.zx_playerItemPlaying()
            }else if state == MediaPlayerState.Failed{
                let error:Error = (self.playerItem?.error!)!
                self.controlView?.zx_playerItemStatusFailed(error: error)
            }
        }
    }
    /** 是否为全屏 */
    var isFullScreen:Bool = false
    /** 是否锁定屏幕方向 */
    var isLocked:Bool = false
    /** 是否在调节音量*/
    var isVolume:Bool = false
    /** 是否被用户暂停 */
    var isPauseByUser:Bool = false
    /** 是否播放本地文件 */
    var isLocalVideo:Bool = false
    /** slider上次的值 */
    var sliderLastValue:CGFloat = 0
    /** 是否再次设置URL播放视频 */
    var repeatToPlay:Bool = false
    /** 播放完了*/
    var playDidEnd:Bool = false
    /** 进入后台*/
    var didEnterBackground:Bool = false
    /** 单击 */
    var singleTap:UITapGestureRecognizer?
    /** 双击 */
    var doubleTap:UITapGestureRecognizer?
    /** 视频URL的数组 */
    var videoURLArray:Array<String>?
    /** slider预览图 */
    var thumbImg:UIImage?
    /** 亮度view */
    lazy var brightnessView = ZXBrightnessShared
    /** 用于全屏展示的视图控制器 */
    var fullScreenViewController:ZXFullscreenPlayerViewController?
    /** 视频填充模式 */
    lazy var videoGravity = AVLayerVideoGravity.resizeAspect
    
    //MARK: - UITableViewCell PlayerView
    
    /** palyer加到tableView */
    var tableView:UITableView?{
        didSet{
            if tableView != nil {
                tableView?.removeObserver(self, forKeyPath: kMediaPlayerViewContentOffset)
            }

            if tableView != nil {
                tableView?.addObserver(self, forKeyPath: kMediaPlayerViewContentOffset, options: NSKeyValueObservingOptions.new, context: nil)
            }
        }
    }
    /** player所在cell的indexPath */
    var indexPath:NSIndexPath?
    /** ViewController中页面是否消失 */
    var viewDisappear:Bool = false
    /** 是否在cell上播放video */
    var isCellVideo:Bool = false
    /** 是否缩小视频在底部 */
    var isBottomVideo:Bool = false
    /** 是否切换分辨率*/
    var isChangeResolution:Bool? = false
    /** 是否正在拖拽 */
    var isDragged:Bool = false
    /** 是否正在旋转屏幕 */
    var isRotating:Bool = false
    
    var playerModel:MediaPlayerModel!{
        didSet{
            if playerModel != nil {
                if playerModel.seekTime > 0 {
                    self.seekTime = playerModel.seekTime
                }
                self.controlView?.zx_playerModel(playerModel: playerModel)
                
                if playerModel?.resolutionDic != nil{
                    self.resolutionDic = playerModel?.resolutionDic
                }
                if playerModel?.tableView != nil && playerModel?.indexPath != nil && playerModel?.videoURL != nil{
                    self.cellVideoWithTableView(tableView: (playerModel?.tableView)!, indexPath: (playerModel?.indexPath)!)
                }
                self.addPlayerToFatherView(view: (playerModel?.fatherView)!)
                self.videoURL = playerModel?.videoURL
            }

        }
    }
    var seekTime:Int = 0
    var videoURL:URL?{
        didSet{
            if videoURL != nil {
                // 每次加载视频URL都设置重播为NO
                self.repeatToPlay = false
                self.playDidEnd   = false
                
                // 添加通知
                self.addNotifications()
                
                self.isPauseByUser = true
                
                // 添加手势
                self.createGesture()
            }
        }
    }
    var resolutionDic:NSDictionary?{
        didSet{
            self.videoURLArray = resolutionDic?.allKeys as? Array<String>
        }
    }
    
    //MARK: public property
    /** 设置playerLayer的填充模式 */
    var playerLayerGravity:MediaPlayerLayerGravity?{
        didSet{
            if playerLayerGravity != nil {
                if playerLayerGravity == MediaPlayerLayerGravity.resize{
                    self.playerLayer?.videoGravity = .resize
                    self.videoGravity = AVLayerVideoGravity(rawValue: String.init(format: "%d", AVLayerVideoGravity.resize as CVarArg))
                }else if playerLayerGravity == MediaPlayerLayerGravity.resizeAspect{
                    self.playerLayer?.videoGravity = .resizeAspect
                    self.videoGravity = AVLayerVideoGravity(rawValue: String.init(format: "%d", AVLayerVideoGravity.resizeAspect as CVarArg))
                }else if playerLayerGravity == MediaPlayerLayerGravity.resizeAspectFill{
                    self.playerLayer?.videoGravity = .resizeAspectFill
                    self.videoGravity = AVLayerVideoGravity(rawValue: String.init(format: "%d", AVLayerVideoGravity.resizeAspectFill as CVarArg))
                }
            }
        }
    }
    /** 是否有下载功能(默认是关闭) */
    var hasDownload:Bool? = false{
        didSet{
            self.controlView?.zx_playerHasDownloadFunction(sender: hasDownload!)
        }
    }
    /** 是否开启预览图 */
    var hasPreviewView:Bool = true
    /** 设置代理 */
    var delegate:MediaPlayerDelegate?
    /** 静音（默认为NO）*/
    var mute:Bool = false
    /** 当cell划出屏幕的时候停止播放（默认为NO） */
    var stopPlayWhileCellNotVisable:Bool = false
    /** 当cell播放视频由全屏变为小屏时候，是否回到中间位置(默认YES) */
    var cellPlayerOnCenter:Bool = true
    /** 是否允许自动转屏, 默认YES */
    var allowAutoRotate:Bool? = false{
        didSet{
            if allowAutoRotate == nil {
                self.removeRotationNotifications()
            }
        }
    }
    /** 允许双指点击进行全屏/非全屏切换, 默认NO */
    var enableFullScreenSwitchWith2Fingers:Bool? = true
    /** 播放器添加到的视图控制器, 包含MediaPlayerView容器视图的视图控制器 */
    var rootViewController:UIViewController?
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.initializeThePlayer()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func awakeFromNib() {
        super.awakeFromNib()
        self.initializeThePlayer()
    }
    
    private func initializeThePlayer(){
        self.cellPlayerOnCenter = true
        self.allowAutoRotate = true

    }
    
    /**
     *  在当前页面，设置新的Player的URL调用此方法
     */
    public func resetToPlayNewURL(){
        self.repeatToPlay = true
        self.resetPlayer()
    }
    
    //MARK - 观察者、通知
    func addNotifications(){
        NotificationCenter.default.addObserver(self, selector: #selector(appDidEnterBackground), name: NSNotification.Name.UIApplicationWillResignActive, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appDidEnterPlayground), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
        
        if self.allowAutoRotate! {
            self.addRotationNotifications()
        }
    }
    
    func addRotationNotifications(){
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        NotificationCenter.default.addObserver(self, selector: #selector(onDeviceOrientationChange), name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onStatusBarOrientationChange), name: NSNotification.Name.UIApplicationDidChangeStatusBarOrientation, object: nil)

    }
    
    func removeRotationNotifications(){
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIApplicationDidChangeStatusBarOrientation, object: nil)

    }
    
    //MARK: - layoutSubviews
    public override func layoutSubviews() {
        super.layoutSubviews()
        self.layoutIfNeeded()
        self.playerLayer?.frame = self.bounds
        UIApplication.shared.isStatusBarHidden = true
    }
    
    //MARK: public method
    static public let sharedPlayerView:ZXMediaPlayerView = ZXMediaPlayerView()
    
    /**
     * 使用自己的控制层可使用此API
     */
    /// 设置视频控制层和播放模型
    ///
    /// - Parameters:
    ///   - controlView: 自定义控制层
    ///   - playerModel: 视频播放模型
    public func playerControlView(controlView:UIView, playerModel:MediaPlayerModel){
        if controlView.isKind(of: ZXMediaControlView.self) {
            let defaultControlView:ZXMediaControlView = ZXMediaControlView.init()
            self.controlView = defaultControlView
        }else{
            self.controlView = controlView as? ZXMediaControlView
        }
        self.playerModel = playerModel
    }
    
    /**
     * 使用自带的控制层时候可使用此API
     */
    public func playerModel(playerModel:MediaPlayerModel){
        let defaultControlView:ZXMediaControlView = ZXMediaControlView.init()
        self.controlView = defaultControlView
        self.playerModel = playerModel
    }
    
    /**
     *  播放视频
     */
    public func playTheVideo(){
        self.configMediaPlayer()
    }
    
    /**
     *  player添加到fatherView上
     */
    public func addPlayerToFatherView(view:UIView){
        if self.fullScreenViewController != nil && self.rootViewController != nil {
            self.isRotating = true
            
            let playerViewSnapshot:UIView = self.snapshotView(afterScreenUpdates: true)!
            playerViewSnapshot.transform = CGAffineTransform.init(rotationAngle: CGFloat(Float.pi*0.5))
            self.rootViewController?.view.addSubview(playerViewSnapshot)
        
            playerViewSnapshot.snp.makeConstraints { (make) in
                make.center.equalTo(0)
                make.width.equalTo((self.rootViewController?.view.snp.height)!)
                make.height.equalTo((self.rootViewController?.view.snp.width)!)
            }
            self.rootViewController?.view.layoutIfNeeded()
        
            self.fullScreenViewController?.dismiss(animated: false) {
                self.removeFromSuperview()
                playerViewSnapshot.addSubview(self)
                self.snp.remakeConstraints({ (make) in
                    make.edges.equalTo(0)
                })
                playerViewSnapshot.layoutIfNeeded()
                
                playerViewSnapshot.snp.remakeConstraints({ (make) in
                    make.edges.equalTo(view)
                })
            UIApplication.shared.setStatusBarOrientation(UIInterfaceOrientation.portrait, animated: false)
                UIView.animate(withDuration: UIApplication.shared.statusBarOrientationAnimationDuration, animations: {
                    playerViewSnapshot.transform = CGAffineTransform.identity
                    self.rootViewController?.view.layoutIfNeeded()
                }, completion: { (finished) in
                    self.removeFromSuperview()
                    playerViewSnapshot.removeFromSuperview()
                    view.addSubview(self)
                    self.snp.makeConstraints({ (make) in
                        make.edges.equalTo(view)
                    })
                    view.layoutIfNeeded()
                    self.isRotating = false
                    
                })
            }
        
        }else{
            if view.isKind(of: UIView.self){
                self.removeFromSuperview()
                view.addSubview(self)
                self.snp.makeConstraints({ (make) in
                    make.edges.equalTo(view)
                })
                view.layoutIfNeeded()
            }
        }
        
    }

    public func resetPlayer(){
        self.playDidEnd = false
        self.playerItem = nil
        self.didEnterBackground = false
        
        self.seekTime = 0
        if (self.timeObserve != nil) {
            self.player?.removeTimeObserver(self.timeObserve ?? "")
            self.timeObserve = nil
        }
        NotificationCenter.default.removeObserver(self)
        self.pause()
        // 移除原来的layer
        self.playerLayer?.removeFromSuperlayer()
        //替换PlayerItem为nil
        self.player?.replaceCurrentItem(with: nil)
//        self.imageGenerator = nil
        self.player = nil
        if self.isChangeResolution! {
            self.controlView?.zx_playerResetControlViewForResolution()
            self.isChangeResolution = false
        }else{
            self.controlView?.zx_playerResetControlView()
        }
        self.controlView = nil
        if !self.repeatToPlay {
            self.removeFromSuperview()
        }
        self.isBottomVideo = false
        // cell上播放视频 && 不是重播时
        if self.isCellVideo && !self.repeatToPlay {
            self.viewDisappear = true
            self.isCellVideo = false
            self.tableView = nil
            self.indexPath = nil
        }
    }
    
    /**
     *  在当前页面，设置新的视频时候调用此方法
     */
    public func resetToPlayNewVideo(playerModel:MediaPlayerModel){
        self.repeatToPlay = true
        self.resetPlayer()
        self.playerModel = playerModel
        self.configMediaPlayer()
    }
    
    /**
     *  播放
     */
    public func play(){
        self.controlView?.zx_playerPlayBtnState(state: true)
        if self.state == MediaPlayerState.Pause {
            self.state = MediaPlayerState.Playing
        }
        self.isPauseByUser = false
        self.player?.play()
        if !self.isBottomVideo {
            self.controlView?.zx_playerCancelAutoFadeOutControlView()
            self.controlView?.zx_playerShowControlView()
        }
    }
    
    /**
     * 暂停
     */
    public func pause(){
        self.controlView?.zx_playerPlayBtnState(state: false)
        if self.state == MediaPlayerState.Playing {
            self.state = MediaPlayerState.Pause
        }
        self.isPauseByUser = true
        self.player?.pause()
    }
    
    //MARK: - Private Method
    
    /**
     *  用于cell上播放player
     *
     *  @param tableView tableView
     *  @param indexPath indexPath
     */
    private func cellVideoWithTableView(tableView:UITableView, indexPath:NSIndexPath){
        // 如果页面没有消失，并且playerItem有值，需要重置player(其实就是点击播放其他视频时候)
        if !self.viewDisappear && self.playerItem != nil {
            self.resetPlayer()
        }
        self.isCellVideo = true
        
        self.viewDisappear = false
        self.tableView = tableView
        self.indexPath = indexPath
        self.controlView?.zx_playerCellPlay()
    }
    
    /**
     *  设置Player相关参数
     */
    private func configMediaPlayer(){
        self.urlAsset = AVURLAsset.init(url: self.videoURL!)
        // 初始化playerItem
        self.playerItem = AVPlayerItem.init(asset: self.urlAsset!)

        self.player = AVPlayer.init(playerItem: self.playerItem)
        
        self.playerLayer = AVPlayerLayer.init(player: self.player)
        self.backgroundColor = UIColor.black
        
        self.playerLayer?.videoGravity = AVLayerVideoGravity(rawValue: self.videoGravity.rawValue)
        self.playerLayer?.contentsScale = UIScreen.main.scale
        
        // 添加播放进度计时器
        self.createTimer()
        // 获取系统音量
        self.configureVolume()
        
        // 本地文件不设置MediaPlayerStateBuffering状态
        if self.videoURL?.scheme == "file" {
            self.state = MediaPlayerState.Playing
            self.isLocalVideo = true
            self.controlView?.zx_playerDownloadBtnState(state: false)
        }else{
            self.state = MediaPlayerState.Buffering
            self.isLocalVideo = false
            self.controlView?.zx_playerDownloadBtnState(state: true)
        }
        self.play()
        self.isPauseByUser = false
    }
    
    /**
     *  创建手势
     */
    private func createGesture(){
        self.singleTap = UITapGestureRecognizer.init(target: self, action: #selector(singleTapAction(gesture:)))
        self.singleTap?.delegate = self
        self.singleTap?.numberOfTapsRequired = 1
        self.singleTap?.numberOfTouchesRequired = 1
        self.addGestureRecognizer(self.singleTap!)
        
        self.doubleTap = UITapGestureRecognizer.init(target: self, action: #selector(doubleTapAction(gesture:)))
        self.doubleTap?.delegate = self
        self.doubleTap?.numberOfTouchesRequired = 1
        self.doubleTap?.numberOfTapsRequired = 2
        self.addGestureRecognizer(self.doubleTap!)
        
        // 解决点击当前view时候响应其他控件事件
        self.singleTap?.delaysTouchesBegan = true
        self.doubleTap?.delaysTouchesBegan = true
        
        // 双击失败响应单击事件
        self.singleTap?.require(toFail: self.doubleTap!)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
            let touch:UITouch = (touches as NSSet).anyObject() as! UITouch
            if touch.tapCount == 1{
                if self.enableFullScreenSwitchWith2Fingers!{
                    self.perform(#selector(singleTapAction(gesture:)), with: false)
                    return
                }
            }else if touch.tapCount == 2{
                NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(singleTapAction(gesture:)), object: nil)
                self.doubleTapAction(gesture:(touch.gestureRecognizers?.last)!)
            }
    }
    
    private func createTimer(){
        weak var weakSelf = self
        self.timeObserve = self.player?.addPeriodicTimeObserver(forInterval: CMTimeMakeWithSeconds(1, 1), queue: nil, using: { (time) in
            let currentItem:AVPlayerItem = weakSelf!.playerItem!
            let loadedRanges:Array<NSValue> = currentItem.seekableTimeRanges
            if loadedRanges.count > 0 && currentItem.duration.timescale != 0{
                let currentTime:Int = Int(CMTimeGetSeconds(currentItem.currentTime())
                )
                let totalTime:CGFloat = CGFloat(Int(currentItem.duration.value)/Int(currentItem.duration.timescale))
                let value:CGFloat = CGFloat(CMTimeGetSeconds(currentItem.currentTime()))/totalTime
                weakSelf!.controlView?.zx_playerCurrentTime(currentTime: currentTime, totalTime: Int(totalTime), value: value)
            }
        })
    }
    
    /**
     *  获取系统音量
     */
    private func configureVolume(){
        let volumeView:MPVolumeView = MPVolumeView()
        self.volumeViewSlider = nil
        for view:UIView in volumeView.subviews {
            if NSStringFromClass(type(of: view)) == "MPVolumeSlider"{
                self.volumeViewSlider = view as? UISlider
                break
            }
        }
        // 使用这个category的应用不会随着手机静音键打开而静音，可在手机静音下播放声音
        let audoSession:AVAudioSession = AVAudioSession.sharedInstance()
        var success:Bool = true
        do {
            try audoSession.setCategory(AVAudioSessionCategoryPlayback)
        } catch  {
            success = false
        }

        if !success {
            // 监听耳机插入和拔掉通知
            NotificationCenter.default.addObserver(self, selector: #selector(audioRouteChangeListenerCallback(notification:)), name: NSNotification.Name.AVAudioSessionRouteChange, object: nil)
        }
    }
    
    /**
     *  耳机插入、拔出事件
     */
    @objc private func audioRouteChangeListenerCallback(notification:Notification){
        let interuptionDict:NSDictionary = notification.userInfo! as NSDictionary
        
        let routeChangeReason:AVAudioSessionRouteChangeReason = interuptionDict.value(forKey: AVAudioSessionRouteChangeReasonKey) as! AVAudioSessionRouteChangeReason
        
        switch routeChangeReason {
        case AVAudioSessionRouteChangeReason.newDeviceAvailable:
            break
        case AVAudioSessionRouteChangeReason.oldDeviceUnavailable:
            //耳机拔掉
            self.play()
            break
        case AVAudioSessionRouteChangeReason.categoryChange:
            break
        case .unknown:
            break
        case .override:
            break
        case .wakeFromSleep:
            break
        case .noSuitableRouteForCategory:
            break
        case .routeConfigurationChange:
            break
        }
    }

    //MARK: - KVO
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard keyPath != nil else {
            return
        }
        let obj = object as? AVPlayerItem
        if obj == self.player?.currentItem {
            if keyPath == "status" {
                if self.player?.currentItem?.status == AVPlayerItemStatus.readyToPlay{
                    self.setNeedsLayout()
                    self.layoutIfNeeded()
                    // 添加playerLayer到self.layer
                    self.layer.insertSublayer(self.playerLayer!, at: 0)

                    self.state = MediaPlayerState.Playing
                    // 加载完成后，再添加平移手势
                    // 添加平移手势，用来控制音量、亮度、快进快退
                    let panRecognizer:UIPanGestureRecognizer = UIPanGestureRecognizer.init(target: self, action: #selector(panDirection(pan:)))
                    panRecognizer.delegate = self
                    panRecognizer.maximumNumberOfTouches = 1
                    panRecognizer.delaysTouchesBegan = true
                    panRecognizer.delaysTouchesEnded = true
                    panRecognizer.cancelsTouchesInView = true
                    self.addGestureRecognizer(panRecognizer)
                    // 跳到xx秒播放视频
                    if self.seekTime > 0{
                        self.seekToTime(dragedSeconds:self.seekTime, complete: { (complete) in
                        })
                    }
                    self.player?.isMuted = self.mute
                }else if self.player?.currentItem?.status == AVPlayerItemStatus.failed{
                    self.state = MediaPlayerState.Failed
                }
            }else if keyPath == "loadedTimeRanges"{
                // 计算缓冲进度
                let timeInterval = self.availableDuration()
                let duration:CMTime? = self.playerItem?.duration
                let totalDuration:CGFloat = CGFloat(CMTimeGetSeconds(duration!))
                self.controlView?.zx_playerSetProgress(progress: CGFloat(timeInterval!)/totalDuration)
            }else if keyPath == "playbackBufferEmpty"{
                // 当缓冲是空的时候
                if (self.playerItem?.isPlaybackBufferEmpty) ?? false{
                    self.state = MediaPlayerState.Buffering
                    self.bufferingSomeSecond()
                }
            }else if keyPath == "playbackLikelyToKeepUp"{
                // 当缓冲好的时候
                if (self.playerItem?.isPlaybackLikelyToKeepUp) ?? false && self.state == MediaPlayerState.Buffering{
                    self.state = MediaPlayerState.Playing
                }
            }
        }else if (obj?.isEqual(self.tableView))!{
            if keyPath == kMediaPlayerViewContentOffset{
                if self.isFullScreen{
                    return
                }
                // 当tableview滚动时处理playerView的位置
                self.handleScrollOffsetWithDict(dict:change! as NSDictionary)
            }
        }

    }
    //MARK: - tableViewContentOffset
        
    /**
     *  KVO TableViewContentOffset
     *
     *  @param dict void
     */
    private func handleScrollOffsetWithDict(dict:NSDictionary){
        let cell:UITableViewCell = self.tableView!.cellForRow(at: self.indexPath! as IndexPath)!
        let visableCells:Array<UITableViewCell> = (self.tableView?.visibleCells)!
        if visableCells.contains(cell) {
            self.updatePlayerViewToCell()
        }else{
            if self.stopPlayWhileCellNotVisable{
                self.resetPlayer()
            }else{
                self.updatePlayerViewToBottom()
            }
        }
    }
            
        /**
         *  缩小到底部，显示小视频
         */
    private func updatePlayerViewToBottom(){
        if self.isBottomVideo {
            return
        }
        self.isBottomVideo = true
        if self.playDidEnd {
            self.repeatToPlay = false
            self.playDidEnd = false
            self.resetPlayer()
            return
        }
        self.layoutIfNeeded()
        UIApplication.shared.keyWindow?.addSubview(self)
        self.snp.remakeConstraints { (make) in
            let width:CGFloat = SCREEN_WIDTH*0.5 - 20
            let height:CGFloat = self.bounds.size.height/self.bounds.size.width
            make.width.equalTo(width)
            make.height.equalTo(self.snp.width).multipliedBy(height)
            make.trailing.equalTo(-10)
            make.bottom.equalTo(-self.tableView!.contentInset.bottom - 10)
        }
        self.controlView?.zx_playerBottomShrinkPlay()
    }

                
        /**
         *  回到cell显示
         */
    private func updatePlayerViewToCell(){
        if !self.isBottomVideo {
            return
        }
        self.isBottomVideo = false
        self.setOrientationPortraitConstraint()
        self.controlView?.zx_playerCellPlay()
    }
                    
        /**
         *  设置横屏的约束
         */
    private func setOrientationLandscapeConstraint(orientation:UIInterfaceOrientation){
        self.toOrientation(orientation:orientation)
        self.isFullScreen = true
    }
    
    /**
     *  设置竖屏的约束
     */
    private func setOrientationPortraitConstraint(){
        if self.isCellVideo {
            let cell:UITableViewCell = (self.tableView?.cellForRow(at: self.indexPath! as IndexPath)!)!
            let visableCells:Array<UITableViewCell> = (self.tableView?.visibleCells)!
            self.isBottomVideo = false
            if !visableCells.contains(cell){
                self.updatePlayerViewToBottom()
            }else{
                self.addPlayerToFatherView(view: (self.playerModel?.fatherView)!)
            }
        }else{
            self.addPlayerToFatherView(view: (self.playerModel?.fatherView)!)
        }
        self.toOrientation(orientation:UIInterfaceOrientation.portrait)
        self.isFullScreen = false
    }
    
    private func toOrientation(orientation:UIInterfaceOrientation){
        // get the direction of statusBar
        let currentOrientation:UIInterfaceOrientation = UIApplication.shared.statusBarOrientation
        // do nothing if the current direction and orientation are the same
        if currentOrientation == orientation {
            return
        }
        // according orientation,remake layout
        if orientation != UIInterfaceOrientation.portrait {
            if !self.allowAutoRotate! && self.rootViewController != nil{
                self.forcePlayerViewRotate2FullScreenOrientationLandscapeRight()
                return
            }
            self.removeFromSuperview()

            UIApplication.shared.keyWindow?.insertSubview(self, belowSubview: self.brightnessView)
            
            self.snp.makeConstraints({ (make) in
                make.width.equalTo(SCREEN_HEIGHT)
                make.height.equalTo(SCREEN_WIDTH)
                make.center.equalTo(UIApplication.shared.keyWindow!)
            })
            

            
        }
        // set false in shouldAutorotate
        UIApplication.shared.setStatusBarOrientation(orientation, animated: false)
        // 获取旋转状态条需要的时间:
        UIView.beginAnimations(nil, context: nil)
        UIView.setAnimationDuration(0.3)
        // 更改了状态条的方向,但是设备方向UIInterfaceOrientation还是正方向的,这就要设置给你播放视频的视图的方向设置旋转
        // 给你的播放视频的view视图设置旋转
        self.transform = CGAffineTransform.identity
        self.transform = self.getTransformRotationAngle()
        // 开始旋转
        UIView.commitAnimations()
        self.controlView?.setNeedsLayout()
        self.controlView?.layoutIfNeeded()
    }
    
    private func forcePlayerViewRotate2FullScreenOrientationLandscapeRight(){
        self.isRotating = true //记录正在旋转屏幕
        if self.fullScreenViewController != nil {
            self.fullScreenViewController = ZXFullscreenPlayerViewController()
            self.fullScreenViewController?.view.backgroundColor = UIColor.black
        }
        
        let containerView:UIView = UIView.init(frame: (self.rootViewController?.view.bounds)!)
        containerView.backgroundColor = .clear
        self.rootViewController?.view.addSubview(containerView)
        
        self.removeFromSuperview()
        containerView.addSubview(self)
        
        containerView.snp.makeConstraints { (make) in
            make.edges.equalTo(0)
        }
        self.snp.remakeConstraints { (make) in
            make.edges.equalTo((self.playerModel?.fatherView)!)
        }
        self.rootViewController?.view.layoutIfNeeded()
        
        self.snp.remakeConstraints { (make) in
            make.center.equalTo(containerView)
            make.width.equalTo(containerView.snp.height)
            make.height.equalTo(containerView.snp.width)
        }
        
        UIView.animate(withDuration: UIApplication.shared.statusBarOrientationAnimationDuration, animations: {
            self.transform = CGAffineTransform.init(rotationAngle: CGFloat.pi/2)
            containerView.backgroundColor = .black
            containerView.layoutIfNeeded()
        }, completion: { (finished) in
            self.fullScreenViewController?.view.backgroundColor = UIColor.clear
            self.rootViewController?.present(self.fullScreenViewController!, animated: false, completion: {
                UIApplication.shared.setStatusBarOrientation(UIInterfaceOrientation.landscapeRight, animated: false)
                self.removeFromSuperview()
                self.transform = CGAffineTransform.identity
                self.fullScreenViewController?.view.addSubview(self)
                
                self.snp.remakeConstraints({ (make) in
                    make.edges.equalTo(0)
                })
                
                self.fullScreenViewController?.view.layoutIfNeeded()
                containerView.removeFromSuperview()
                
                self.isRotating = false  //选转屏幕结束
            })
        })
    }

    
        /**
         * 获取变换的旋转角度
         *
         * @return 角度
         */
    private func getTransformRotationAngle() -> CGAffineTransform {
        // 状态条的方向已经设置过,所以这个就是你想要旋转的方向
        let orientation:UIInterfaceOrientation = UIApplication.shared.statusBarOrientation
        
        // 根据要进行旋转的方向来计算旋转的角度
        if orientation == UIInterfaceOrientation.portrait {
            return CGAffineTransform.identity
        }else if orientation == UIInterfaceOrientation.landscapeLeft{
            return CGAffineTransform.init(rotationAngle: -CGFloat.pi/2)
        }else if orientation == UIInterfaceOrientation.landscapeRight{
            return CGAffineTransform.init(rotationAngle: CGFloat.pi/2)
        }
        return CGAffineTransform.identity

    }
    
    //MARK: 屏幕转屏相关
    /**
     *  屏幕转屏
     *
     *  @param orientation 屏幕方向
     */
    private func interfaceOrientation(orientation:UIInterfaceOrientation){
        if orientation == UIInterfaceOrientation.landscapeRight || orientation == UIInterfaceOrientation.landscapeLeft {
            //设置横屏
            self.setOrientationLandscapeConstraint(orientation:orientation)
        }else if orientation == UIInterfaceOrientation.portrait{
            self.setOrientationPortraitConstraint()
        }
    }
    
    /**
     *  屏幕方向发生变化会调用这里
     */
    @objc private func onDeviceOrientationChange(){
        if self.player == nil {
            return
        }
        if ZXBrightnessShared.isLockScreen {
            return
        }
        if self.didEnterBackground {
            return
        }
        let orientation:UIDeviceOrientation = UIDevice.current.orientation
        let interfaceOrientation:UIInterfaceOrientation = UIInterfaceOrientation.init(rawValue: orientation.rawValue)!
        if orientation == UIDeviceOrientation.faceUp || orientation == UIDeviceOrientation.faceDown || orientation == UIDeviceOrientation.unknown {
            return
        }
        
        switch interfaceOrientation {
        case .portraitUpsideDown:
            break
        case .portrait:
            if self.isFullScreen{
                self.toOrientation(orientation: UIInterfaceOrientation.portrait)
            }
            break
        case .landscapeLeft:
            if self.isFullScreen == false{
                self.toOrientation(orientation: .landscapeLeft)
                self.isFullScreen = true
            }else{
                self.toOrientation(orientation: .landscapeLeft)
            }
            break
        case .landscapeRight:
            if self.isFullScreen == false{
                self.toOrientation(orientation: .landscapeRight)
                self.isFullScreen = true
            }else{
                self.toOrientation(orientation: .landscapeRight)
            }
            break
        default:
            break
        }
    }
    
    // 状态条变化通知（在前台播放才去处理）
    @objc private func onStatusBarOrientationChange(){
        if !self.didEnterBackground {
            //获取到当前状态条的方向
            let currentOrientation:UIInterfaceOrientation = UIApplication.shared.statusBarOrientation
            if currentOrientation == .portrait{
                self.setOrientationPortraitConstraint()
                if self.cellPlayerOnCenter{
                    self.tableView?.scrollToRow(at: self.indexPath! as IndexPath, at: .middle, animated: false)
                }
                self.brightnessView.removeFromSuperview()
                UIApplication.shared.keyWindow?.addSubview(self.brightnessView)

                self.brightnessView.snp.remakeConstraints({ (make) in
                    make.width.height.equalTo(155)
                    make.leading.equalTo((SCREEN_WIDTH-155)*0.5)
                    make.top.equalTo((SCREEN_HEIGHT-155)*0.5)
                })
            }else{
                if currentOrientation == .landscapeRight{
                    self.toOrientation(orientation: .landscapeRight)
                }else if currentOrientation == .landscapeLeft{
                    self.toOrientation(orientation: .landscapeLeft)
                }
                self.brightnessView.removeFromSuperview()
                self.addSubview(self.brightnessView)

                self.brightnessView.snp.remakeConstraints({ (make) in
                    make.center.equalTo(self)
                    make.width.height.equalTo(155)
                })
            }
        }
    }
    
    /**
     *  锁定屏幕方向按钮
     *
     *  @param sender UIButton
     */
    private func lockScreenAction(sender:UIButton){
        sender.isSelected = !sender.isSelected
        self.isLocked = sender.isSelected
        // 调用AppDelegate单例记录播放状态是否锁屏，在TabBarController设置哪些页面支持旋转
        ZXBrightnessShared.isLockScreen = sender.isSelected
    }
    
    /**
     *  解锁屏幕方向锁定
     */
    private func unLockTheScreen(){
        self.controlView?.zx_playerLockBtnState(state: false)
        self.isLocked = false
        self.interfaceOrientation(orientation: .portrait)
    }

    //MARK: -  缓冲递归回调
    /**
     *  缓冲递归回调处理
     */
    private func bufferingSomeSecond(){
        self.state = MediaPlayerState.Buffering
        // playbackBufferEmpty会反复进入，因此在bufferingOneSecond延时播放执行完之前再调用bufferingSomeSecond都忽略
        var isBuffering:Bool = false
        if isBuffering {
            return
        }
        isBuffering = true
        
        // 需要先暂停一小会之后再播放，否则网络状况不好的时候时间在走，声音播放不出来
        self.player?.play()
        DispatchQueue.main.asyncAfter(deadline: .now()+1) {
            // 如果此时用户已经暂停了，则不再需要开启播放了
            if self.isPauseByUser{
                isBuffering = false
                return
            }
            self.play()
            
            // 如果执行了play还是没有播放则说明还没有缓存好，则再次缓存一段时间
            isBuffering = false
            if !(self.playerItem?.isPlaybackLikelyToKeepUp)!{
                self.bufferingSomeSecond()
            }
        }
    }
    
    //MARK: - 缓冲进度
    /**
     *  计算缓冲进度
     *
     *  @return 缓冲进度
     */
    private func availableDuration() -> TimeInterval? {
        if let loadedTimeRanges = self.player?.currentItem?.loadedTimeRanges,
            let first = loadedTimeRanges.first {
            let timeRange = first.timeRangeValue
            let startSeconds = CMTimeGetSeconds(timeRange.start)
            let durationSecound = CMTimeGetSeconds(timeRange.duration)
            let result = startSeconds + durationSecound
            return result
        }
        return 0
    }

    //MARK: - Action
    /**
     *   轻拍方法
     *
     *  @param gesture UITapGestureRecognizer
     */
    @objc private func singleTapAction(gesture:UIGestureRecognizer){
        if gesture.isKind(of: NSNumber.self) {
            self._fullScreenAction()
            return
        }
        if gesture.state == UIGestureRecognizerState.recognized {
            if self.isBottomVideo && !self.isFullScreen{
                self._fullScreenAction()
            }else{
                if self.playDidEnd{
                    return
                }else{
                    self.controlView?.zx_playerShowControlView()
                }
            }
        }
    }
    
    /**
     *  双击播放/暂停
     *
     *  @param gesture UITapGestureRecognizer
     */
   @objc private func doubleTapAction(gesture:UIGestureRecognizer){
        if self.playDidEnd {
            return
        }
        self.controlView?.zx_playerCancelAutoFadeOutControlView()
        self.controlView?.zx_playerShowControlView()
        if self.isPauseByUser {
            self.play()
        }else{
            self.pause()
        }
    }
    
    /** 全屏 */
    private func _fullScreenAction(){
        if ZXBrightnessShared.isLockScreen {
            self.unLockTheScreen()
            return
        }
        if self.isFullScreen {
            self.interfaceOrientation(orientation: .portrait)
            self.isFullScreen = false
            return
        }else{
            let orientation:UIDeviceOrientation = UIDevice.current.orientation
            if orientation == .landscapeRight{
                self.interfaceOrientation(orientation: .landscapeLeft)
            }else{
                self.interfaceOrientation(orientation: .landscapeRight)
            }
            self.isFullScreen = true
        }
    }
    
    //MARK: - NSNotification Action
    /**
     *  播放结束
     *
     *  @param notification 通知
     */
    @objc private func moviePlayDidEnd(notification:Notification){
        self.state = MediaPlayerState.Stopped
        if self.isBottomVideo && !self.isFullScreen {
            // 播放完了，如果是在小屏模式 && 在bottom位置，直接关闭播放器
            self.repeatToPlay = false
            self.playDidEnd = false
            self.resetPlayer()
        }else{
            if !self.isDragged{
                // 如果不是拖拽中，直接结束播放
                self.playDidEnd = true
                self.controlView?.zx_playerPlayEnd()
            }
        }
    }
    
    /**
     *  应用退到后台
     */
    @objc private func appDidEnterBackground(){
        if self.didEnterBackground == true {
            // 退到后台锁定屏幕方向
            ZXBrightnessShared.isLockScreen = true
            self.player?.pause()
            self.state = MediaPlayerState.Pause
        }
    }
    
    /**
     *  应用进入前台
     */
    @objc private func appDidEnterPlayground(){
        self.didEnterBackground = false
        // 根据是否锁定屏幕方向 来恢复单例里锁定屏幕的方向
        ZXBrightnessShared.isLockScreen = self.isLocked
        if !self.isPauseByUser {
            self.state = MediaPlayerState.Playing
            self.isPauseByUser = false
            self.play()
        }
    }

    /**
     *  从xx秒开始播放视频跳转
     *
     *  @param dragedSeconds 视频跳转的秒数
     */
    private func seekToTime(dragedSeconds:Int, complete completionHandler:@escaping (Bool)->Void){
        if self.player?.currentItem?.status == AVPlayerItemStatus.readyToPlay {
            self.controlView?.zx_playerActivity(animated: true)
            self.player?.pause()
            let draggedTime:CMTime = CMTime.init(value: CMTimeValue(dragedSeconds), timescale: 1)
            weak var weakSelf = self
            self.player?.seek(to: draggedTime, toleranceBefore: CMTime.init(value: 1, timescale: 1), toleranceAfter: CMTime.init(value: 1, timescale: 1), completionHandler: { (complted) in
                weakSelf?.controlView?.zx_playerActivity(animated: false)
                
                completionHandler(complted)
                
                weakSelf?.player?.play()
                weakSelf?.seekTime = 0
                weakSelf?.isDragged = false
                
                //结束滑动
                weakSelf?.controlView?.zx_playerDraggedEnd()
                if !(weakSelf?.isLocalVideo)!{
                    if (weakSelf?.playerItem?.isPlaybackLikelyToKeepUp)!{
                        weakSelf?.state = MediaPlayerState.Playing
                    }else{
                        weakSelf?.state = MediaPlayerState.Buffering
                    }
                }
            })
        }
    }

    //MARK: - UIPanGestureRecognizer手势方法
    /**
     *  pan手势事件
     *
     *  @param pan UIPanGestureRecognizer
     */
    @objc private func panDirection(pan:UIPanGestureRecognizer){
        //根据在view上Pan的位置，确定是调音量还是亮度
        let locationPoint:CGPoint = pan.location(in: self)
        // 我们要响应水平移动和垂直移动
        // 根据上次和本次移动的位置，算出一个速率的point
        let veloctyPoint:CGPoint = pan.velocity(in: self)
        
        switch pan.state {
        case .began:
            let x:CGFloat = fabs(veloctyPoint.x)
            let y:CGFloat = fabs(veloctyPoint.y)
            if x > y{
                self.panDirection = PanDirection.HorizontalMoved
                let time = self.player?.currentTime()
                self.sumTime = CGFloat(time!.value)/CGFloat(time!.timescale)
            }else if x < y{
                self.panDirection = PanDirection.VerticalMoved
                if locationPoint.x > self.bounds.size.width/2{
                    self.isVolume = true
                }else{
                    self.isVolume = false
                }
            }
            break
        case .changed:
            if self.panDirection == PanDirection.HorizontalMoved{
                self.horizontalMoved(value:veloctyPoint.x)
            }else if self.panDirection == PanDirection.VerticalMoved{
                self.verticalMoved(value:veloctyPoint.y)
            }
            break
        case .ended:
            if self.panDirection == PanDirection.HorizontalMoved{
                self.isPauseByUser = false
                self.seekToTime(dragedSeconds: Int(self.sumTime), complete: { (complete) in
                })
                self.sumTime = 0
            }else{
                self.isVolume = false
            }
            break
        default:
            break
        }
    }

    
    /**
     *  pan垂直移动的方法
     *
     *  @param value void
     */
    private func verticalMoved(value:CGFloat){
        if self.volumeViewSlider != nil {
            self.isVolume ? (self.volumeViewSlider?.value -= Float(value) / 10000) : (UIScreen.main.brightness -= value / 10000)

        }
    }
    
    /**
     *  pan水平移动的方法
     *
     *  @param value void
     */
    private func horizontalMoved(value:CGFloat){
        // 每次滑动需要叠加时间
        self.sumTime = self.sumTime + value/200
        
        // 需要限定sumTime的范围
        let totalTime = self.playerItem?.duration
        let totalMovieDuration:CGFloat = CGFloat(totalTime!.value)/CGFloat(totalTime!.timescale)
        if self.sumTime > totalMovieDuration {
            self.sumTime = totalMovieDuration
        }
        if self.sumTime < 0 {
            self.sumTime = 0
        }
        
        var style:Bool = false
        if value > 0 {
            style = true
        }
        if value < 0 {
            style = false
        }
        if value == 0 {
            return
        }
        
        self.isDragged = true
        self.controlView?.zx_playerDraggedTime(draggedTime: Int(self.sumTime), totalTime: Int(totalMovieDuration), isForward: style, hasPreView: false)

    }

    /// caculate the length of string
    ///
    /// - Parameter time: time(Int)
    /// - Returns: string
    private func durationStringWithTime(time:Int) -> String{
        //获取分钟
        let min = String.init(format: "%02d", time/60)
        // 获取秒数
        let sec = String.init(format: "%02d", time%60)
        
        let str:String = String.init(format: "%@:%@", min,sec)
        return str
    }

    //MARK: - UIGestureRecognizerDelegate
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if gestureRecognizer.isKind(of: UIPanGestureRecognizer.self) {
            if self.isCellVideo && !self.isFullScreen || self.playDidEnd || self.isLocked{
                return false
            }
        }
        if gestureRecognizer.isKind(of: UITapGestureRecognizer.self) {
            if self.isBottomVideo && !self.isFullScreen{
                return false
            }
        }
        if (touch.view?.isKind(of: UISlider.self))! {
            return false
        }
        return true
    }
    
    //MARK: - deinit
    deinit {
        self.playerItem = nil
        self.tableView  = nil
        ZXBrightnessShared.isLockScreen = false
        self.controlView?.zx_playerCancelAutoFadeOutControlView()
        
        NotificationCenter.default.removeObserver(self)
        UIDevice.current.endGeneratingDeviceOrientationNotifications()
        
        if self.timeObserve != nil {
            self.player?.removeTimeObserver(self.timeObserve ?? "")
            self.timeObserve = nil
        }
        
        if playerItem != nil {
            NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: playerItem)
            playerItem?.removeObserver(self, forKeyPath: "status")
            playerItem?.removeObserver(self, forKeyPath: "loadedTimeRanges")
            playerItem?.removeObserver(self, forKeyPath: "playbackBufferEmpty")
            playerItem?.removeObserver(self, forKeyPath: "playbackLikelyToKeepUp")
            
        }
    }

}

//MARK: - ZXMediaControlViewDelegate
extension ZXMediaPlayerView {
    func playAction(_ controlView: ZXMediaControlView, button: UIButton) {
        if self.playDidEnd {
            return
        }
        self.isPauseByUser = !self.isPauseByUser
        if self.isPauseByUser {
            self.pause()
            if self.state == MediaPlayerState.Playing{
                self.state = MediaPlayerState.Pause
            }
        } else {
            self.play()
            if self.state == MediaPlayerState.Pause{
                self.state = MediaPlayerState.Playing
            }
        }
        
    }
    
    func progressSliderTouchBegan(_ controlView: ZXMediaControlView, slide: ZXValueTrackingSlider) {
        
    }
    
    func progressSliderValueChanged(_ controlView: ZXMediaControlView, slide: ZXValueTrackingSlider) {
        // 拖动改变视频播放进度
        if (self.player?.currentItem?.status == AVPlayerItemStatus.readyToPlay) {
            self.isDragged = true
            var style = false
            
            let value = CGFloat(slide.value) - self.sliderLastValue
            if value > 0 {
                style = true
            }
            if value < 0{
                style = false
            }
            if value == 0{
                return
            }
            
            self.sliderLastValue  = CGFloat(slide.value)
            
            let totalTime = CGFloat((self.playerItem?.duration.value)!)/CGFloat((self.playerItem?.duration.timescale)!)
            
            //计算出拖动的当前秒数
            let draggedSeconds = totalTime*CGFloat(slide.value)
            
            //转换成CMTime才能给player来控制播放进度
            let dragedCMTime = CMTime.init(value: CMTimeValue(draggedSeconds), timescale: 1)
            
            controlView.zx_playerDraggedTime(draggedTime: Int(draggedSeconds), totalTime: Int(totalTime), isForward: style, hasPreView: self.isFullScreen ? self.isFullScreen : false)
            
            if totalTime > 0{//总时长 > 0时候才能拖动slider
                if self.isFullScreen && self.hasPreviewView{
                    self.imageGenerator.cancelAllCGImageGeneration()
                    self.imageGenerator.appliesPreferredTrackTransform = true
                    self.imageGenerator.maximumSize = CGSize.init(width: 100, height: 56)
                    
                    self.imageGenerator.generateCGImagesAsynchronously(forTimes: [NSValue.init(time: dragedCMTime)], completionHandler: { (requestedTime, im, actualTime, result, error) in
                        if result != AVAssetImageGeneratorResult.succeeded{
                            DispatchQueue.main.async {
                                
                                var preImage = self.thumbImg
                                if self.thumbImg == nil{
                                    preImage = ZXMediaPlayerImage("MediaPlayer_loading_bgView")
                                }
                                controlView.zx_playerDraggedTime(draggedTime: Int(draggedSeconds), slideImage: preImage!)
                            }
                        }else{
                            var preImage = UIImage.init(cgImage: im!)
                            if im == nil{
                                preImage = ZXMediaPlayerImage("MediaPlayer_loading_bgView")
                            }
                            DispatchQueue.main.async {
                                controlView.zx_playerDraggedTime(draggedTime: Int(draggedSeconds), slideImage: preImage)
                            }
                        }
                    })
                    
                }
            }else{
                slide.value = 0
            }
        }else{
            slide.value = 0
        }
    }
    
    func progressSliderTouchEnded(_ controlView: ZXMediaControlView, slide: ZXValueTrackingSlider) {
        if self.player?.currentItem?.status == AVPlayerItemStatus.readyToPlay {
            self.isPauseByUser = false
            self.isDragged = false
            //视频总时间长度
            let totalTime = CGFloat((self.playerItem?.duration.value)!)/CGFloat((self.playerItem?.duration.timescale)!)
            
            //计算出拖动的当前秒数
            let draggedSeconds = totalTime*CGFloat(slide.value)
            
            self.seekToTime(dragedSeconds: Int(draggedSeconds)){ (finished) in}
        }
        self.playDidEnd = false
    }
    
    func progressSliderTap(_ controlView: ZXMediaControlView, slideValue: CGFloat) {
        // 视频总时间长度
        let total = CGFloat((self.playerItem?.duration.value)!)/CGFloat((self.playerItem?.duration.timescale)!)
        
        //计算出拖动的当前秒数
        let draggedSeconds = total*slideValue
        
        self.controlView?.zx_playerPlayBtnState(state: true)
        self.seekToTime(dragedSeconds: Int(draggedSeconds)) { (finished) in}
    }
    
    func fullScreenAction(_ controlView: ZXMediaControlView, button: UIButton) {
        self._fullScreenAction()
    }
    
    func lockScreenAction(_ controlView: ZXMediaControlView, button: UIButton) {
        self.isLocked = button.isSelected
        // 调用AppDelegate单例记录播放状态是否锁屏
        ZXBrightnessShared.isLockScreen = button.isSelected
        
    }
    
    func closeAction(_ controlView: ZXMediaControlView, button: UIButton) {
        self.resetPlayer()
        self.removeFromSuperview()
    }
    
    func backAction(_ controlView: ZXMediaControlView, button: UIButton) {
        if ZXBrightnessShared.isLockScreen {
            self.unLockTheScreen()
        }else{
            if !self.isFullScreen{
                self.pause()
                delegate?.zx_playerBackAction()
            }else{
                self.interfaceOrientation(orientation: UIInterfaceOrientation.portrait)
            }
        }
    }
    
    func repeatPlayAction(_ controlView: ZXMediaControlView, button: UIButton) {
        // 没有播放完
        self.playDidEnd   = false
        // 重播改为NO
        self.repeatToPlay = false
        self.seekToTime(dragedSeconds: 0) { (finished) in}
        
        if self.videoURL?.scheme == "file" {
            self.state = MediaPlayerState.Playing
        }else{
            self.state = MediaPlayerState.Buffering
        }
    }
    
    func downloadVideoAction(_ controlView: ZXMediaControlView, button: UIButton) {
        delegate?.zx_playerDownload(url: (self.videoURL?.absoluteString)!)
    }
    
    func centerPlayAction(_ controlView: ZXMediaControlView, button: UIButton) {
        
    }
    
    func failAction(_ controlView: ZXMediaControlView, button: UIButton) {
        self.configMediaPlayer()
    }
    
    func resolutionAction(button: UIButton) {
        // 记录切换分辨率的时刻
        let currentTime = CMTimeGetSeconds((self.player?.currentTime())!)
        let videoStr = self.videoURLArray![button.tag - 200]
        let videoURL = URL.init(string: videoStr)
        
        if videoURL == self.videoURL {
            return
        }
        self.isChangeResolution = true
        
        self.resetToPlayNewURL()
        self.videoURL = videoURL
        
        self.seekTime = Int(currentTime)
        
        self.playTheVideo()
    }
}
