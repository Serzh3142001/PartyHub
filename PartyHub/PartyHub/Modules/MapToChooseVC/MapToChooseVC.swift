//
//  MapToChooseVC.swift
//  PartyHub
//
//  Created by Dinar Garaev on 19.08.2022.
//

import UIKit
import PinLayout
import CoreLocation
import MapKit
import YandexMapsMobile

final class CurLocationButton: UIButton {
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        return bounds.insetBy(dx: -44, dy: -44).contains(point)
    }
}

final class MapToChooseVC: UIViewController {

    // MARK: - Private Properties

    var resPoint = GeoPoint(name: "place", latitude: nil, longtitude: nil)
    var currentLocation: CLLocation?
    weak var addNewEventVC: AddNewEventVC?
    private var userLocationLayer: YMKUserLocationLayer!
    private let mapView = YMKMapView()
    private let currentLocationButton = CurLocationButton()
    private var flagLocation = false
    private var flagStartDragMap = false
    private var locationManager = CLLocationManager()
    private var tapGestureReconizer = UITapGestureRecognizer()
    private let location = UIImage(named: "location")
    private let locationDot = UIImageView(image: UIImage(systemName: "circle.fill"))
    private var locView = UIImageView()
    private let adressLabel = UILabel()

    private let chooseButton: UIButton = {
        let button = UIButton(type: .system)
        button.layer.masksToBounds = true
        button.backgroundColor = .systemIndigo
        button.layer.cornerRadius = 15
        button.setTitle("Choose", for: .normal)
        button.tintColor = .white
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        button.addTarget(self, action: #selector(didTapChooseButton), for: .touchUpInside)
        return button
    }()

    private let searchController: UISearchController = {
        let viewController = UISearchController(searchResultsController: nil)
        viewController.searchBar.placeholder = "Поиск"
        viewController.searchBar.tintColor = .label
        viewController.searchBar.searchBarStyle = .minimal
        viewController.definesPresentationContext = true
        return viewController
    }()

    // MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        setupLayout()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    // MARK: - Methods

    func createDeniedAlertController() {
        let alert = UIAlertController(
            title: "Требуется разрешение, чтобы найти вас",
            message: "Пожалуйста, включите разрешение в настройках",
            preferredStyle: .alert
        )
        let cancelAction = UIAlertAction(title: "Cancel", style: .destructive)
        let settingsAction = UIAlertAction(
            title: "Settings",
            style: .default
        ) { [weak self] _ in
            self?.openSettings()
        }
        alert.addAction(cancelAction)
        alert.addAction(settingsAction)
        present(alert, animated: true)
    }

    func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString),
              UIApplication.shared.canOpenURL(url) else { return }
        UIApplication.shared.open(url)
    }

    func getUserLocation() {
        locationManager.requestAlwaysAuthorization()

        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.startUpdatingLocation()
        }

        let mapKit = YMKMapKit.sharedInstance()
        userLocationLayer = mapKit.createUserLocationLayer(with: mapView.mapWindow)
        userLocationLayer.setVisibleWithOn(true)
        userLocationLayer.isHeadingEnabled = true
        userLocationLayer.setObjectListenerWith(self)

        mapView.mapWindow.map.addCameraListener(with: self)

        currentLocationButton.setImage(UIImage(systemName: "location"), for: .normal)
        currentLocationButton.backgroundColor = .systemGray6
        currentLocationButton.tintColor = .label
        currentLocationButton.layer.cornerRadius = 20
        currentLocationButton.addTarget(self, action: #selector(clickedCurrentLocationButton), for: .touchUpInside)
    }

    // MARK: - Private Metods
    private func setup() {

        view.backgroundColor = .systemGray6
        view.addSubview(mapView)
        mapView.addSubview(currentLocationButton)
        mapView.addSubview(chooseButton)
        locView = UIImageView(image: location)
        mapView.addSubview(locView)
        mapView.addSubview(locationDot)
        mapView.addSubview(currentLocationButton)
        locView.addSubview(adressLabel)

        adressLabel.layer.borderWidth = 1
        adressLabel.layer.cornerRadius = 6
        adressLabel.layer.borderColor = UIColor(red: 255, green: 255, blue: 255, alpha: 1).cgColor
        adressLabel.layer.backgroundColor = UIColor(red: 255, green: 255, blue: 255, alpha: 1).cgColor
        adressLabel.font = .systemFont(ofSize: 20, weight: .medium)
        adressLabel.textColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1)
        adressLabel.textAlignment = .center
        adressLabel.numberOfLines = 0

        locationDot.layer.masksToBounds = true
        locationDot.tintColor = .systemIndigo
        locationDot.alpha = 0

        tapGestureReconizer = UITapGestureRecognizer(target: self, action: #selector(closeKeyboard))

        navigationItem.title = "Map"
        searchController.searchResultsUpdater = self
        searchController.searchBar.delegate = self
        navigationItem.searchController = searchController

        getUserLocation()
    }

    private func setupLayout() {
        mapView.pin.all()

        locView.pin
            .height(120)
            .width(100)
            .marginBottom(32)
            .center()

        locationDot.pin
            .height(5)
            .width(5)
            .marginBottom(1)
            .marginRight(0.3)
            .center()

        chooseButton.pin
            .bottom(50)
            .left(20)
            .right(20)
            .height(50)

        currentLocationButton.pin
            .bottomRight(to: chooseButton.anchor.topRight)
            .height(40)
            .width(40)
            .marginBottom(20)

        adressLabel.pin
            .bottomCenter(to: locView.anchor.topCenter)
            .height(30)
            .marginBottom(-20)
            .maxWidth(UIScreen.main.bounds.width)
            .sizeToFit(.height)
    }

    private func updateAdress(completion: (() -> Void)? = nil) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        adressLabel.text = " ...    "
        adressLabel.pin
            .bottomCenter(to: self.locView.anchor.topCenter)
            .height(30)
            .marginBottom(-20)
            .sizeToFit(.height)

        let latitude = mapView.mapWindow.map.cameraPosition.target.latitude
        let longitude = mapView.mapWindow.map.cameraPosition.target.longitude

        let location = CLLocation(latitude: latitude, longitude: longitude)

        let group: DispatchGroup = DispatchGroup()
        var adressPart1: String = ""
        var adressPart2: String = ""

        group.enter()
        location.fetchCityAndCountry { name, error, arg  in
            adressPart1 = name ?? "-"
            group.leave()
        }

        group.enter()
        location.fetchName { name, error in
            adressPart2 = name ?? "-"
            group.leave()
        }

        group.notify(queue: DispatchQueue.main) {
            print(adressPart1, adressPart2)
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            self.adressLabel.text = " \(adressPart1), \(adressPart2)  "
            self.resPoint = {
                GeoPoint(name: self.adressLabel.text!, latitude: latitude, longtitude: longitude)
            }()
            self.adressLabel.pin
                .bottomCenter(to: self.locView.anchor.topCenter)
                .height(30 * CGFloat(Int(self.adressLabel.intrinsicContentSize.width / UIScreen.main.bounds.width) + 1))
                .marginBottom(10)
                .maxWidth(UIScreen.main.bounds.width)
                .sizeToFit(.height)

            completion?()
            print(latitude, longitude)
        }
    }
}

// MARK: - Actions
private extension MapToChooseVC {
    @objc
    func clickedCurrentLocationButton() {
        guard let location = currentLocation else {
            createDeniedAlertController()
            return
        }

        mapView.mapWindow.map.move(
            with: YMKCameraPosition(
                target: YMKPoint(
                    latitude: location.coordinate.latitude,
                    longitude: location.coordinate.longitude
                ),
                zoom: 15,
                azimuth: 0,
                tilt: 0
            ),
            animationType: YMKAnimation(
                type: YMKAnimationType.smooth,
                duration: 0.3
            ),
            cameraCallback: nil
        )
    }

    @objc
    func closeKeyboard() {
        if !searchController.isActive { return }
        print(#function)

        view.endEditing(true)
        navigationController?.view.endEditing(true)
    }

    @objc
    func didTapChooseButton() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        guard let adress = adressLabel.text else {
            return
        }

        if !adress.contains("...") {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            addNewEventVC?.choosedPoint = resPoint
            addNewEventVC?.updateAdress()
            navigationController?.popViewController(animated: true)
        } else {
            updateAdress() {
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    self.addNewEventVC?.choosedPoint = self.resPoint
                    self.addNewEventVC?.updateAdress()
                    self.navigationController?.popViewController(animated: true)
                }
            }
        }
    }
}

// MARK: - UISearchResultsUpdating, UISearchBarDelegate
extension MapToChooseVC: UISearchResultsUpdating, UISearchBarDelegate {
    func updateSearchResults(for searchController: UISearchController) {
        return
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let query = searchController.searchBar.text,
              !query.trimmingCharacters(in: .whitespaces).isEmpty
        else { return }

        print(query)
        let JSONAdress = query.replacingOccurrences(of: " ", with: "+", options: .literal, range: nil)

        NetworkManager.shared.getCoordinates(
            with: JSONAdress,
            curLocation: GeoPoint(
                name: "curLoc",
                latitude: currentLocation?.coordinate.latitude,
                longtitude: currentLocation?.coordinate.longitude
            )
        ) { result in
            DispatchQueue.main.async { [weak self] in
                switch result {
                case .success(let res):
                    guard let longtitude = res.longtitude,
                          let latitude = res.latitude
                    else { return }

                    self?.mapView.mapWindow.map.move(
                        with: YMKCameraPosition(
                            target: YMKPoint(
                                latitude: longtitude,
                                longitude: latitude
                            ),
                            zoom: 15,
                            azimuth: 0,
                            tilt: 0
                        ),
                        animationType: YMKAnimation(
                            type: YMKAnimationType.smooth,
                            duration: 1
                        ),
                        cameraCallback: nil
                    )

                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) { [weak self] in
                        self?.updateAdress()
                    }

                case .failure(let error):
                    let alertController = UIAlertController(title: nil, message: error.rawValue, preferredStyle: .alert)
                    let okAction = UIAlertAction(title: "OK", style: .cancel)
                    alertController.addAction(okAction)
                    self?.present(alertController, animated: true, completion: nil)
                    print("ГГ\nError! \(error.localizedDescription)")
                }
            }
        }
    }
}

// MARK: - UISearchControllerDelegate
extension MapToChooseVC: UISearchControllerDelegate {
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        view.addGestureRecognizer(tapGestureReconizer)
    }

    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        view.removeGestureRecognizer(tapGestureReconizer)
    }
}

// MARK: - YMKUserLocationObjectListener
extension MapToChooseVC: YMKUserLocationObjectListener {
    func onObjectAdded(with view: YMKUserLocationView) {
        let pinPlacemark = view.pin.useCompositeIcon()
        pinPlacemark.setIconWithName(
            "searchResult",
            image: UIImage(named: "searchResult") ?? UIImage(),
            style: YMKIconStyle(
                anchor: CGPoint(x: 0.5, y: 0.5) as NSValue,
                rotationType: YMKRotationType.rotate.rawValue as NSNumber,
                zIndex: 1,
                flat: true,
                visible: true,
                scale: 1,
                tappableArea: nil
            )
        )

        view.accuracyCircle.fillColor = UIColor.systemIndigo.withAlphaComponent(0.8)
    }

    func onObjectRemoved(with view: YMKUserLocationView) {}

    func onObjectUpdated(with view: YMKUserLocationView, event: YMKObjectEvent) {}
}

extension MapToChooseVC: YMKMapCameraListener {
    func onCameraPositionChanged(with map: YMKMap, cameraPosition: YMKCameraPosition, cameraUpdateReason: YMKCameraUpdateReason, finished: Bool) {
        if finished {
            updateAdress()
            flagStartDragMap = false
//            setupLayout()
            UIView.animate(withDuration: 0.3, delay: 0) {
                self.locView.pin
                    .height(120)
                    .width(100)
                    .marginBottom(32)
                    .center()
            }
            UIView.animate(withDuration: 0.3, delay: 0.2) {
                self.locationDot.alpha = 0
            }
            debugPrint("+++++")
        } else if !flagStartDragMap {
            flagStartDragMap = true
            adressLabel.text = " ...    "
            adressLabel.pin
                .bottomCenter(to: self.locView.anchor.topCenter)
                .height(30)
                .marginBottom(-20)
                .sizeToFit(.height)

            UIView.animate(withDuration: 0.3, delay: 0) {
                self.locationDot.alpha = 1
                self.locView.pin
                    .height(120)
                    .width(100)
                    .marginBottom(65)
                    .center()
            }
            debugPrint("-----")
        }
    }
}

// MARK: - CLLocationManagerDelegate
extension MapToChooseVC: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        currentLocation = locations.last!
        if !flagLocation {
            guard currentLocation != nil else {
                return
            }
            flagLocation = true

            clickedCurrentLocationButton()
        }
    }
}

// MARK: - EventViewController
final class EventViewController: UIViewController {

    // TODO: - убрать позже
    private let coordLabel = UILabel()
    private let point: GeoPoint

    init(point: GeoPoint) {
        self.point = point
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }

    private func setup() {
        title = point.name
        coordLabel.text = "\(point.latitude!), \(point.longtitude!)"
        coordLabel.font = .systemFont(ofSize: 25, weight: .bold)
        coordLabel.numberOfLines = 0
        view.backgroundColor = .systemBackground
        view.addSubview(coordLabel)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        coordLabel.pin
            .center()
            .maxWidth(UIScreen.main.bounds.width)
            .sizeToFit()
    }
}