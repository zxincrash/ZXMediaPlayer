//
//  UIWindow+ ZXExtension.swift
//  ZXValueTrackingSlider
//
//  Created by zhaoxin on 2017/11/23.
//  Copyright © 2017年 zhaoxin. All rights reserved.
//

import UIKit

extension UIWindow {
    
    func zx_currentViewController() -> UIViewController {
        var topVC:UIViewController = self.rootViewController!
        while true {
            if topVC.presentedViewController != nil{
                topVC = topVC.presentedViewController!
            }else if topVC is UINavigationController{
                let nav:UINavigationController = topVC as! UINavigationController
                topVC = nav.topViewController!
            }else if topVC is UITabBarController{
                let tabVC:UITabBarController = topVC as! UITabBarController
                topVC = tabVC.selectedViewController!
            }else{
                break
            }
        }
        
        return topVC
        
    }
}
