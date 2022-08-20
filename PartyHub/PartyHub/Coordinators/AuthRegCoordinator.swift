//
//  AuthRegCoordinator.swift
//  PartyHub
//
//  Created by Dinar Garaev on 18.08.2022.
//

import UIKit

final class AuthRegCoordinator: Coordinator {
    let router = DefaultRouter(with: nil)
    var result: ((FlowResult<Void>) -> Void)?

    init() {
        (router.toPresent() as? UINavigationController)?.setNavigationBarHidden(false, animated: false)
        start()
    }

    func start() {
        let module = LoginVC()
        module.title = "Login"
        module.navigation = { [weak self] navType in
            switch navType {
            case .enter:
                self?.result?(.success(Void()))
            case .register:
                self?.presentRegistration()
            case .back:
                self?.result?(.canceled)
            }
        }
        router.setRootModule(module)
    }

    func presentRegistration() {
        let module = RegistrationVC()
        module.title = "Registration"
        let nav = UINavigationController(rootViewController: module)
        module.navigation = { [weak self] typeNav in
            switch typeNav {
            case .back:
                self?.router.popModule(animated: true)
            case .enter:
                self?.router.popModule(animated: false)
                self?.result?(.success(Void()))
            case .alert:
                break
            }
        }
        router.present(nav, animated: true, completion: nil)
    }

    func toPresent() -> UIViewController {
        return router.toPresent()
    }
}