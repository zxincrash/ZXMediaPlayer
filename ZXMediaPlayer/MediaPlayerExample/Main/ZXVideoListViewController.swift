//
//  ZXVideoListViewController.swift
//  ZXMediaPlayer
//
//  Created by zhaoxin on 2017/12/4.
//  Copyright © 2017年 zhaoxin. All rights reserved.
//

import UIKit

class ZXVideoListViewController: ZXBaseViewController ,UITableViewDelegate,UITableViewDataSource{
    var videoInfo:ZXVideoInfo = ZXVideoInfo()
    let identifier = "VidelListCell"

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 10
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath)
        
//        let cell = tableView.dequeueReusableCell(withIdentifier: identifier) ?? UITableViewCell.init(style: .default, reuseIdentifier: identifier)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return SMALL_SCREEN_HEIGHT
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)
        
        let model = MediaPlayerModel()
        model.videoURL = URL.init(string: (self.videoInfo.playUrl))
        model.title = self.videoInfo.title
        model.placeholderImageURLString = self.videoInfo.coverForFeed
        model.fatherView = cell?.contentView
        model.indexPath = indexPath as NSIndexPath
        
        
        self.mediaPlayerView.playerModel(playerModel: model)
        self.mediaPlayerView.playTheVideo()
    }

    lazy var mediaPlayerView: ZXMediaPlayerView = {
        let sharedPlayerView = ZXMediaPlayerView.sharedPlayerView
        
        sharedPlayerView.allowAutoRotate = true
        sharedPlayerView.rootViewController = self
        sharedPlayerView.cellPlayerOnCenter = false
        
        return sharedPlayerView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.addSubview(self.listTable)
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    lazy var listTable: UITableView = {
        let table = UITableView.init(frame: CGRect.init(x: 0, y: 64, width: self.view.frame.size.width, height: self.view.frame.size.height - 64), style: UITableViewStyle.plain)
        table.dataSource = self
        table.delegate = self
        table.register(UITableViewCell.self, forCellReuseIdentifier: identifier)
        return table
    }()

}
