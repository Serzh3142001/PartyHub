//
//  AppDelegate.swift
//  PartyHub
//
//  Created by Сергей Николаев on 09.08.2022.
//

import UIKit
import YandexMapsMobile

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    private var appCoordinator: Presentable?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        YMKMapKit.setApiKey("d0ee692b-3897-4784-99ca-0c0896e50e1e")
        YMKMapKit.sharedInstance()
        startApp()
        return true
    }

    func application(
        _ application: UIApplication,
        supportedInterfaceOrientationsFor window: UIWindow?
    ) -> UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask(rawValue: UIInterfaceOrientationMask.portrait.rawValue)
    }
}

extension AppDelegate {

    // MARK: - Private Methods

    private func startApp() {
        if window == nil {
            window = UIWindow(frame: UIScreen.main.bounds)
        }

        let menuCordinator = MenuCoordinator()
        menuCordinator.start()
        let mapCordinator = MapCoordinator()
        mapCordinator.start()
        let profileCordinator = ProfileCoordinator()
        profileCordinator.start()

        appCoordinator = TabBarCoordinator(with: [
            .init(module: menuCordinator, icon: UIImage(systemName: "list.bullet")!, title: "Menu", tag: 0),
            .init(module: mapCordinator, icon: UIImage(systemName: "map")!, title: "Map", tag: 1),
            .init(module: profileCordinator, icon: UIImage(systemName: "person.circle")!, title: "Profile", tag: 2)
        ])

        window?.rootViewController = appCoordinator?.toPresent()
        window?.makeKeyAndVisible()
    }
}

// TODO: - вынести в отдельный extension
// UIApplication.shared.windows.filter {$0.isKeyWindow}.first.rootViewController
extension UIApplication {
    class func topViewController(
        controller: UIViewController? = UIApplication.shared.windows.filter {$0.isKeyWindow}.first?.rootViewController
    ) -> UIViewController? {
        if let navigationController = controller as? UINavigationController {
            return topViewController(controller: navigationController.visibleViewController)
        }
        if let tabController = controller as? UITabBarController {
            if let selected = tabController.selectedViewController {
                return topViewController(controller: selected)
            }
        }
        if let presented = controller?.presentedViewController {
            return topViewController(controller: presented)
        }
        return controller
    }
}
