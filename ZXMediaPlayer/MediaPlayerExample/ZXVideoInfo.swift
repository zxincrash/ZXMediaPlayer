//
//  ZXVideoInfo.swift
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

public struct ZXVideoInfo {
    /** 标题 */
    let title:String = "测试"
    /** 描述 */
    let video_description:String = "hao"
    /** 视频地址 */
    let playUrl:String = "http://wvideo.spriteapp.cn/video/2016/0328/56f8ec01d9bfe_wpd.mp4"
    /** 封面图 */
    let coverForFeed:String = "http://img.wdjimg.com/image/video/ef5af677657e81b0cf79b73349446f43_0_0.jpeg"
    /** 视频分辨率的数组 */
    var playInfo:NSMutableArray = NSMutableArray()
    
    public init()
    {
        
    }
}
