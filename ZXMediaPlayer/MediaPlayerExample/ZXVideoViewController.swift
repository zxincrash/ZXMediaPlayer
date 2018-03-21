//
//  ZXVideoViewController.swift
//  ZXMediaPlayer
//
//  Created by zhaoxin on 2017/11/23.
//  Copyright © 2017年 zhaoxin. All rights reserved.
//

import UIKit

class ZXVideoViewController: ZXBaseViewController {
    var videoInfo:ZXVideoInfo = ZXVideoInfo()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

        self.view.addSubview(self.coverView)
        self.coverView.setModel(model: self.videoInfo)
        
        weak var weakSelf = self
        self.coverView.playBlock =  { (button) -> Void in
            
            let model = MediaPlayerModel()
            model.videoURL = URL.init(string: (weakSelf?.videoInfo.playUrl)!)
            model.title = weakSelf?.videoInfo.title
            model.placeholderImageURLString = weakSelf?.videoInfo.coverForFeed
            model.fatherView = weakSelf?.coverView
            
            weakSelf?.mediaPlayerView.playerModel(playerModel: model)
            weakSelf?.mediaPlayerView.playTheVideo()
        }
        
        
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle{
        // 这里设置横竖屏不同颜色的statusbar
        if (ZXBrightnessShared.isLandscape)! {
            return UIStatusBarStyle.lightContent
        }
        return UIStatusBarStyle.default
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask{
        return UIInterfaceOrientationMask.portrait
    }
    
    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation{
        return UIInterfaceOrientation.portrait
    }
    
    override var prefersStatusBarHidden: Bool{
        return false
    }
    
    override var shouldAutorotate: Bool {
        return false
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    lazy var coverView: ZXMediaCoverView = {
        let view = ZXMediaCoverView.init(frame: CGRect.init(x: 0, y: 64, width: SCREEN_WIDTH, height: SMALL_SCREEN_HEIGHT))
        view.backgroundColor = UIColor.black
        return view
    }()
    lazy var mediaPlayerView: ZXMediaPlayerView = {
        let sharedPlayerView = ZXMediaPlayerView.sharedPlayerView
        
        sharedPlayerView.allowAutoRotate = true
        sharedPlayerView.rootViewController = self
                
        return sharedPlayerView
    }()
}

