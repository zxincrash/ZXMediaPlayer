//
//  ZXNavigationController.swift
//  ZXMediaPlayer
//
//  Created by zhaoxin on 2017/12/4.
//  Copyright © 2017年 zhaoxin. All rights reserved.
//

import UIKit

class ZXNavigationController: UINavigationController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Navigation
    // 是否支持自动转屏
    override var shouldAutorotate: Bool{
        return (self.visibleViewController?.shouldAutorotate)!
    }
    
    // 支持哪些屏幕方向
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask{
        return (self.visibleViewController?.supportedInterfaceOrientations)!
    }
    
    // 默认的屏幕方向（当前ViewController必须是通过模态出来的UIViewController（模态带导航的无效）方式展现出来的，才会调用这个方法）
    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation{
        return (self.visibleViewController?.preferredInterfaceOrientationForPresentation)!
    }
    
    override var childViewControllerForStatusBarStyle: UIViewController?{
        return self.visibleViewController
    }
    
    override var childViewControllerForStatusBarHidden: UIViewController?{
        return self.visibleViewController
    }

}
