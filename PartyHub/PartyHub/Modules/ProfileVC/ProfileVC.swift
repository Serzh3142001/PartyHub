//
//  ProfileVC.swift
//  PartyHub
//
//  Created by juliemoorled on 14.08.2022.
//

import UIKit
import FirebaseAuth
import PinLayout

class ProfileVC: UIViewController {

    // MARK: - Internal properties

    enum Navigation {
        case exit
        case removeAccount
    }

    var navigation: ((Navigation) -> Void)?
    let favoriteEventsVC = FavoriteEventsVC()
    let createdEventsVC = CreatedEventsVC()
    private let moreNavigationItem = UIBarButtonItem(
        image: UIImage(systemName: "ellipsis"),
        style: .plain,
        target: self,
        action: nil
    )

    // MARK: - Private properties

    private let activityIndicator = LoadindIndicatorView()

    private let iconImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "person.crop.circle"))
        imageView.layer.masksToBounds = true
        imageView.tintColor = .systemIndigo
        imageView.contentMode = .scaleToFill
        return imageView
    }()

    private let emailLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 17, weight: .semibold)
        label.textColor = .label
        label.textAlignment = .center
        return label
    }()

    private let toggleView = ProfileToggleView()

    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.isPagingEnabled = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        return scrollView
    }()

    // MARK: - Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupDelegates()
        addChildren()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setupEmail()
        if #available(iOS 14.0, *) {
            moreNavigationItem.menu = createAccountMenu()
        } else {
            // Fallback on earlier versions
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        setUpLayout()
    }

    // MARK: - Actions

    @objc
    private func moreButtonTapped() {
        presentActionSheet()
    }

    // MARK: - Private Methods

    private func presentActionSheet() {
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let removeAction = UIAlertAction(title: "Удалить аккаунт", style: .destructive) { [weak self] _ in
            self?.presentDeletionAlert()
        }
        let exitAction = UIAlertAction(title: "Выйти", style: .default) { [weak self] _ in
            self?.navigation?(.exit)
        }
        let cancelAction = UIAlertAction(title: "Отмена", style: .cancel, handler: nil)

        actionSheet.addAction(exitAction)
        if AuthManager.shared.currentUser()?.uid != AuthManager.shared.adminUid {
            actionSheet.addAction(removeAction)
        }
        actionSheet.addAction(cancelAction)

        present(actionSheet, animated: true, completion: nil)
    }

    private func createAccountMenu() -> UIMenu {
        let removeAction = UIAction(
            title: "Удалить аккаунт",
            image: UIImage(systemName: "trash"),
            attributes: .destructive
          ) { [unowned self] (_) in
              self.presentDeletionAlert()
          }

        let exitAction = UIAction(
            title: "Выйти",
            image: UIImage(systemName: "rectangle.portrait.and.arrow.right")
        ) { [unowned self] (_) in
            self.navigation?(.exit)
        }

        var menuActions = [exitAction]
        if AuthManager.shared.currentUser()?.uid != AuthManager.shared.adminUid {
            menuActions.append(removeAction)
        }

        let addNewMenu = UIMenu(
            title: "",
            children: menuActions)

          return addNewMenu
    }

    private func presentDeletionAlert() {
        let alert = UIAlertController(title: "Подтверждение", message: "Вы уверены, что хотите удалить аккаунт?", preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "Отмена", style: .cancel)
        let removeAction = UIAlertAction(title: "Удалить", style: .destructive) { [weak self] _ in
            self?.activityIndicator.start()
            self?.navigation?(.removeAccount)
        }
        alert.addAction(cancelAction)
        alert.addAction(removeAction)

        present(alert, animated: true, completion: nil)
    }

    private func setupEmail() {
        guard let email = AuthManager.shared.currentUser()?.email else { return }
        emailLabel.text = email
    }

    private func setupUI() {
        if #available(iOS 14.0, *) {
            moreNavigationItem.menu = createAccountMenu()
        } else {
            // Fallback on earlier versions
        }

        moreNavigationItem.tintColor = .label
        navigationItem.rightBarButtonItem = moreNavigationItem

        view.backgroundColor = .systemBackground

        view.addSubview(iconImageView)
        view.addSubview(emailLabel)
        view.addSubview(scrollView)
        view.addSubview(toggleView)

        NotificationCenter.default.addObserver(self, selector: #selector(didCompleteDeletionSuccess), name: NSNotification.Name("AuthManager.SignOutDeleteSuccess.Sirius.PartyHub"), object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(didCompleteDeletionFailure), name: NSNotification.Name("AuthManager.SignOutDeleteFailure.Sirius.PartyHub"), object: nil)
    }

    private func setUpLayout() {
        let basicPadding: CGFloat = 12
        let imageViewWidth: CGFloat = view.frame.width / 4

        iconImageView.pin
            .top(view.safeAreaInsets.top + basicPadding*2)
            .hCenter()
            .width(imageViewWidth)
            .height(imageViewWidth)

        emailLabel.pin
            .top(iconImageView.frame.maxY + basicPadding)
            .hCenter(to: iconImageView.edge.hCenter)
            .width(view.frame.width*0.8)
            .height(24)

        scrollView.pin
            .top(emailLabel.frame.maxY + basicPadding*2)
            .right()
            .left()
            .bottom()
        scrollView.contentSize = CGSize(width: view.width * 2, height: scrollView.height)

        toggleView.pin
            .top(emailLabel.frame.maxY + basicPadding)
            .width(view.frame.width)
            .height(55)

        activityIndicator.pinToRootVC(rootVC: self)
    }

    private func setupDelegates() {
        scrollView.delegate = self
        toggleView.delegate = self
    }

    private func addChildren() {
        addChild(favoriteEventsVC)
        scrollView.addSubview(favoriteEventsVC.view)
        favoriteEventsVC.view.frame = CGRect(
            x: 0,
            y: 0,
            width: scrollView.width,
            height: scrollView.height
        )
        favoriteEventsVC.didMove(toParent: self)

        addChild(createdEventsVC)
        scrollView.addSubview(createdEventsVC.view)
        createdEventsVC.view.frame = CGRect(
            x: view.width,
            y: 0,
            width: scrollView.width,
            height: scrollView.height
        )
        createdEventsVC.didMove(toParent: self)
    }

    @objc
    private func didCompleteDeletionSuccess() {
        activityIndicator.stopSuccess()
    }

    @objc
    private func didCompleteDeletionFailure() {
        activityIndicator.stopFailure()
    }
}

// MARK: - UIScrollViewDelegate

extension ProfileVC: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.x >= (view.width - 100) {
            toggleView.update(for: .created)
        } else {
            toggleView.update(for: .favorites)
        }
    }
}

// MARK: - ProfileToggleViewDelegate

extension ProfileVC: ProfileToggleViewDelegate {
    func profileToggleViewDidTapFavorites(_ toggleView: ProfileToggleView) {
        UIView.animate(withDuration: 0.3) {
            self.scrollView.contentOffset = .zero
        }
    }

    func profileToggleViewDidTapCreated(_ toggleView: ProfileToggleView) {
        UIView.animate(withDuration: 0.3) {
            self.scrollView.contentOffset = CGPoint(x: self.view.width, y: 0)
        }
    }
}
