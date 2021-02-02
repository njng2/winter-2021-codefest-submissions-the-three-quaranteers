//
//  ViewController.swift
//  codefest
//
//  Created by Patrick Chaca on 1/12/21.
//

import UIKit
import GoogleMaps
import GooglePlaces
import SwiftyJSON
import Alamofire
import Firebase
import FirebaseDatabase
import Cosmos
import DropDown
class MapViewController: UIViewController, GMSMapViewDelegate, GMSAutocompleteViewControllerDelegate{
        
    @IBOutlet weak var settingButton: UIButton!
    var locationManager: CLLocationManager!
    var selectedButton: Bool!
    var currentLocation: CLLocation?
    @IBOutlet weak var mapView: GMSMapView!
    var placesClient: GMSPlacesClient!
    var preciseLocationZoomLevel: Float = 15.0
    var approximateLocationZoomLevel: Float = 10.0
    var ref: DatabaseReference!
    @IBOutlet weak var searchButton: UIButton!
    var passOver: GMSPlace!
    @IBOutlet weak var addButton: UIButton!
    var oldRoute: GMSPolyline!
    
    fileprivate var locationMarker : GMSMarker? = GMSMarker()

    private var infoWindow = CustomInfoWindow()

    override func viewDidLoad() {
        super.viewDidLoad()
        //To add functionality to mapview delegate, this needs to be done
        mapView.delegate = self
        
        do{
            if let styleURL = Bundle.main.url(forResource: "style", withExtension: "json"){
                mapView.mapStyle = try GMSMapStyle(contentsOfFileURL: styleURL)
            }else{
                NSLog("Unable to find style.json")
            }
        }catch{
                NSLog("One or more of the map styles failed to load. \(error)")
        }
        // Initialize the location manager.
        locationManager = CLLocationManager()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.distanceFilter = 50
        locationManager.startUpdatingLocation()
        locationManager.delegate = self
        
        // Create a map.
        mapView.isMyLocationEnabled = true
        mapView.settings.myLocationButton = true
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        mapView.isMyLocationEnabled = true

        drawMarkers()
        
        
    }
    
    
    
    //When the view loads, it'll draw the markers onto the map
    func drawMarkers(){
        let db = Firestore.firestore()
        db.collection("geolocation").addSnapshotListener({ [self]querySnapshot, error in
            guard let documents = querySnapshot?.documents else{
                print("Error fetching document: \(error!)")
                return
            }
            for document in documents{
                print("\(document.documentID) => \(document.data())")
                print(type(of: document.data()["longitude"]))
                let lat = document.data()["latitude"]
                let long = document.data()["longitude"]
                let name =  document.data()["name"]
                let address = document.data()["address"]
                let position = CLLocationCoordinate2D(latitude: lat as! CLLocationDegrees, longitude: long as! CLLocationDegrees)
                
                

                DispatchQueue.main.async(execute: {
                    let marker = GMSMarker()
                    marker.position = position
                    //marker.title = name as? String
                    //marker.snippet = address as? String
                    marker.map = self.mapView
                    // *IMPORTANT* Assign all the spots data to the marker's userData property
                    
                    marker.userData = document.data()
                })
            }
        })
    }
    
    //This function allows us to draw the path when the user clicks on the marker
    func drawPath(destination: CLLocationCoordinate2D){
        let currentlocation = locationManager.location!.coordinate
        let start = "\(currentlocation.latitude),\(currentlocation.longitude)"
        let end = "\(destination.latitude),\(destination.longitude)"
        let url =  "https://maps.googleapis.com/maps/api/directions/json?origin=\(start)&destination=\(end)&mode=walking&key=AIzaSyCa7QvPcW4LRhbflCGpU6_J23iwyl-XwOE"
        AF.request(url).responseJSON { (response) in
            guard let data = response.data else {
                return
            }
            do{
                let jsonData = try JSON(data: data)
                let routes = jsonData["routes"].arrayValue
                for route in routes{
                    let overview_polyline = route["overview_polyline"].dictionary
                    let points = overview_polyline?["points"]?.string
                    let path = GMSPath.init(fromEncodedPath: points ?? "")
                    let polyline = GMSPolyline.init(path: path)
                    polyline.strokeColor = .systemGreen
                    polyline.strokeWidth = 5
                    if(self.oldRoute != nil){
                        if(polyline.path?.encodedPath() == self.oldRoute.path?.encodedPath()){ //encoded string of the path compared to each other
                            self.oldRoute.map = nil //this turns off the direction if the user presses on it again
                            self.oldRoute = nil
                        }
                        else{
                                self.oldRoute.map = nil
                                self.oldRoute = nil
                                self.oldRoute = polyline
                                self.oldRoute.map = self.mapView
                        }
                    }
                    else{
                        self.oldRoute = polyline
                        self.oldRoute.map = self.mapView
                    }
                    
 
                    
                    
                    
                }
            }
            catch let error{
                print(error.localizedDescription)
            }
            
        }
    }
    
    
    //This checks when the button was pressed
    func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
        
        infoWindow.removeFromSuperview()
        infoWindow = loadNiB()
        
        
        var markerData : NSDictionary?
            if let data = marker.userData! as? NSDictionary {
                markerData = data
            }
        locationMarker = marker
        guard let location = locationMarker?.position else {
                print("locationMarker is nil")
                return false
            }
        let name = markerData!["name"]!
        let address = markerData!["address"]!
        let accessibility = markerData!["accessible"]!
        let hygiene = markerData!["cleanliness"]!
        let capacity = markerData!["shared"]!
        let rating = markerData!["stars"]!
        infoWindow.name.text = name as? String
        infoWindow.name.adjustsFontSizeToFitWidth = true
        infoWindow.address.adjustsFontSizeToFitWidth = true
        infoWindow.address.text = address as? String
        infoWindow.stars.settings.fillMode = .precise
        infoWindow.stars.rating = rating as! Double
        infoWindow.stars.settings.updateOnTouch = false
        if accessibility as! Bool == true{
            infoWindow.accessibility.text = "Yes"
        }
        else{
            infoWindow.accessibility.text = "None"
        }
        if capacity as! Bool == true{
            infoWindow.capacity.text = "Multiple"
        }
        else{
            infoWindow.capacity.text = "Single"
        }
        if hygiene as! Bool == true{
            infoWindow.hygiene.text = "Clean"
        }
        else{
            infoWindow.hygiene.text = "Dirty"
        }
        infoWindow.spotData = markerData
        infoWindow.delegate = infoWindow.self
        // Configure UI properties of info window
        infoWindow.alpha = 0.9
        infoWindow.layer.cornerRadius = 12
        infoWindow.layer.borderWidth = 2
        infoWindow.layer.borderColor = UIColor(named: "053568")?.cgColor
        infoWindow.layer.cornerRadius = 40 // height/2 / 2
        infoWindow.center = mapView.projection.point(for: location)
        infoWindow.center.y = infoWindow.center.y - 82
        self.view.addSubview(infoWindow)
        let destination = CLLocationCoordinate2D(latitude: marker.position.latitude, longitude: marker.position.longitude)
        drawPath(destination: destination)
        mapView.selectedMarker = marker
        let camera = GMSCameraPosition.camera(withLatitude: marker.position.latitude,
            longitude: marker.position.longitude,
            zoom: 15.0)
        mapView.animate(to: camera)
        return false
    }
    func mapView(_ mapView: GMSMapView, didChange position: GMSCameraPosition) {
        if (locationMarker != nil){
            guard let location = locationMarker?.position else {
                print("locationMarker is nil")
                return
            }
            infoWindow.center = mapView.projection.point(for: location)
            infoWindow.center.y = infoWindow.center.y - 100
        }
    }
    
    func mapView(_ mapView: GMSMapView, didTapAt coordinate: CLLocationCoordinate2D) {
        infoWindow.removeFromSuperview()
    }
    
    @IBAction func autcompleteClicked(_ sender: UIButton) {
        if sender == addButton{
                selectedButton = true
        }
        let autocompleteController = GMSAutocompleteViewController()
            autocompleteController.delegate = self

            // Specify the place data types to return.
        let fields: GMSPlaceField = [.all]
            autocompleteController.placeFields = fields

            // Specify a filter.
            let filter = GMSAutocompleteFilter()
        filter.type = .establishment
            autocompleteController.autocompleteFilter = filter

            // Display the autocomplete view controller.
            present(autocompleteController, animated: true, completion: nil)
        

    }
    func loadNiB() -> CustomInfoWindow {
        let infoWindow = CustomInfoWindow.instanceFromNib() as! CustomInfoWindow
        return infoWindow
    }
    
    @IBAction func showOptions(_ sender: Any) {
        showAlert()
    }
    
    func showAlert(){
        let alert = UIAlertController(title: "Log out", message: nil , preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { action in
            print("tapped Dismiss")
        }))
        alert.addAction(UIAlertAction(title: "Confirm", style: .destructive, handler: { action in
            do{
                try Auth.auth().signOut()
                let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
                let homeController = storyBoard.instantiateViewController(identifier: "WelcomeViewController") as WelcomeViewController
                homeController.modalPresentationStyle = .fullScreen
                self.present(homeController, animated: true, completion: nil)
                
            }
            catch{
                print("Couldn't sign out")
            }
        }))
        present(alert, animated:true)
    }
    
    //extension MapViewController: GMSAutocompleteViewControllerDelegate{
    
    // Handle the user's selection.
      func viewController(_ viewController: GMSAutocompleteViewController, didAutocompleteWith place: GMSPlace) {
        print("Place name: \(place.name)")
        print("Place ID: \(place.placeID)")
        print("Place Location: \(place.coordinate)")
        print("Latitude: \(place.coordinate.latitude)")
        print("Longitude: \(place.coordinate.longitude)")
        if (selectedButton == true){
            
            passOver = place
            selectedButton = false
            let popover = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "PopUp") as! PopUpViewController
            self.addChild(popover)
            popover.view.frame = self.view.frame
            self.view.addSubview(popover.view)
            popover.didMove(toParent: self)
            popover.places = place
            popover.name.text = place.formattedAddress!
            passOver = nil
        }
        let zoomLevel = locationManager.accuracyAuthorization == .fullAccuracy ? preciseLocationZoomLevel : approximateLocationZoomLevel
        let camera = GMSCameraPosition.camera(withLatitude: place.coordinate.latitude,
            longitude: place.coordinate.longitude,
            zoom: zoomLevel)
        mapView.animate(to: camera)
        dismiss(animated: true, completion: nil)
      }

        
      func viewController(_ viewController: GMSAutocompleteViewController, didFailAutocompleteWithError error: Error) {
        // TODO: handle the error.
        print("Error: ", error.localizedDescription)
      }

      // User canceled the operation.
      func wasCancelled(_ viewController: GMSAutocompleteViewController) {
        dismiss(animated: true, completion: nil)
      }

      // Turn the network activity indicator on and off again.
      func didRequestAutocompletePredictions(_ viewController: GMSAutocompleteViewController) {
       // UIApplication.shared.isNetworkActivityIndicatorVisible = true
      }

      func didUpdateAutocompletePredictions(_ viewController: GMSAutocompleteViewController) {
       // UIApplication.shared.isNetworkActivityIndicatorVisible = false
      }
    
}



// Delegates to handle events for the location manager.
extension MapViewController: CLLocationManagerDelegate{

  // Handle incoming location events.
  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    let location: CLLocation = locations.last!
    print("Location: \(location)")
    let zoomLevel = locationManager.accuracyAuthorization == .fullAccuracy ? preciseLocationZoomLevel : approximateLocationZoomLevel
    let camera = GMSCameraPosition.camera(withLatitude: location.coordinate.latitude,
        longitude: location.coordinate.longitude,
        zoom: zoomLevel)
    mapView.animate(to: camera)
  }

  // Handle authorization for the location manager.
  func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
    // Check accuracy authorization
    let accuracy = manager.accuracyAuthorization
    switch accuracy {
    case .fullAccuracy:
        print("Location accuracy is precise.")
    case .reducedAccuracy:
        print("Location accuracy is not precise.")
    @unknown default:
      fatalError()
    }
    
    // Handle authorization status
    switch status {
    case .restricted:
      print("Location access was restricted.")
    case .denied:
      print("User denied access to location.")
      // Display the map using the default location.
      mapView.isHidden = false
    case .notDetermined:
      print("Location status not determined.")
    case .authorizedAlways: fallthrough
    case .authorizedWhenInUse:
      print("Location status is OK.")
    @unknown default:
      fatalError()
    }
  }

  // Handle location manager errors.
  func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    locationManager.stopUpdatingLocation()
    print("Error: \(error)")
  }
    
}

