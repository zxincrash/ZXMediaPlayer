//
//  ZXMediaCoverView.swift
//  ZXMediaPlayer (https://github.com/zxin2928/ZXMediaPlayer)
//
//  Created by zhaoxin on 2017/11/28.
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

typealias PlayBlock = (_ sender:UIButton) -> Void

class ZXMediaCoverView: UIView {
    var picView:UIImageView?
    var titleLabel:UILabel?
    var playBtn:UIButton?
    
    var playBlock:PlayBlock?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.isUserInteractionEnabled = true
        picView = UIImageView.init(frame: CGRect.init(x: 0, y: 0, width: frame.size.width, height: frame.size.height))
        picView?.image = ZXMediaPlayerImage("MediaPlayer_loading_bgView")
        self.picView?.isUserInteractionEnabled = true
        self.addSubview(picView!)

        playBtn = UIButton.init(type: .custom)
        playBtn?.frame.size = CGSize.init(width: 50, height: 50)
        playBtn?.center = CGPoint.init(x: (picView?.center.x)!, y: (picView?.center.y)!)
        playBtn?.setImage(UIImage.init(named: "video_list_cell_big_icon"), for: .normal)
        playBtn?.addTarget(self, action: #selector(playAction(sender:)), for: .touchDown)
        picView?.addSubview(playBtn!)
        
    }
    func setModel(model:ZXVideoInfo) {
        self.titleLabel?.text = model.title

    }
    
    @objc func playAction(sender:UIButton ){
        if playBlock != nil {
            playBlock!(sender)
        }
        
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
