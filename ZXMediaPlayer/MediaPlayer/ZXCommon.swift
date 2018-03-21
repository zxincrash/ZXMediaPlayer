//
//  ZXCommon.swift
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

let SCREEN_WIDTH:CGFloat = UIScreen.main.bounds.width
let SCREEN_HEIGHT:CGFloat = UIScreen.main.bounds.height

let SCREEN_BOUNDS:CGRect = UIScreen.main.bounds

let SMALL_SCREEN_HEIGHT:CGFloat = SCREEN_WIDTH*9/16

let MediaPlayerOrientationIsLandscape = UIDeviceOrientationIsLandscape(UIDevice.current.orientation)
let MediaPlayerOrientationIsPortrait = UIDeviceOrientationIsPortrait(UIDevice.current.orientation)

let ZXBrightnessShared = ZXBrightnessView.shareInstance()

private func MediaPlayerSrcName(file:String) -> String {
    let bundleStr:NSString = "ZXMediaPlayer.bundle" as NSString
    return bundleStr.appendingPathComponent(file) as String
}

private func MediaPlayerFrameworkSrcName(file:String) -> String {
    let bundleStr:NSString = "Frameworks/MediaPlayer.framework/ZXMediaPlayer.bundle" as NSString
    
    return bundleStr.appendingPathComponent(file) as String
}

func ZXMediaPlayerImage(_ file:String) -> UIImage {
    if MediaPlayerSrcName(file: file).count>0 {
        return UIImage.init(named: MediaPlayerSrcName(file: file))!
    }else{
        return UIImage.init(named: MediaPlayerFrameworkSrcName(file: file))!
    }
}

func RGBA(_ r:CGFloat, _ g:CGFloat, _ b:CGFloat, _ a:CGFloat) -> UIColor {
    return UIColor.init(red: r/255, green: g/255, blue: b/255, alpha: a)
}

let kMediaPlayerViewContentOffset:String = "contentOffset"
