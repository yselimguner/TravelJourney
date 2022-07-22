//
//  ViewController.swift
//  TravelJourney
//
//  Created by Yavuz Güner on 20.07.2022.
//

import UIKit
import MapKit
import CoreLocation
import CoreData

class ViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {

    @IBOutlet weak var mapView: MKMapView!
    
    @IBOutlet weak var commentText: UITextField!
    @IBOutlet weak var nameText: UITextField!
    var locationManager = CLLocationManager() //konumla alakalı işlem yapacağımız zaman bu nesneyi çağırıcaz.
    
    var choosenLatitude = Double()
    var choosenLongitude = Double() //selectLocation içerisinden veriyi almak için yazarız.
    
    var selectedTitle = ""
    var selectedTitleID : UUID?
    
    var annotationTitle = ""
    var annotationSubtitle = ""
    var annotationLatitude = Double()
    var annotationLongitude = Double()
    

    override func viewDidLoad() {
        super.viewDidLoad()

        mapView.delegate = self
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest //en iyi lokasyon alma budur. En çok pili yer.
        locationManager.requestWhenInUseAuthorization() //Sadece app'i kullanırken izin iste. Info pliste git.
        locationManager.startUpdatingLocation() //Kullanııcınn yerini bununla alırız.
        
        
        //Pin eklemek için önce tıklama özelliğini aktif ederiz.
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(selectLocation(gestureRecognizer:))) //Uzun basınca çağırılacak gestureRecognizer oluştururz.
        
        gestureRecognizer.minimumPressDuration = 3 //3 sn basarsan bunu algıla anlamına geliyor.
        mapView.addGestureRecognizer(gestureRecognizer)
        
        //Eğer seçilen yer boşsa yeni bir yer eklemeye çalışıyoruz için yazarız.
        if selectedTitle != "" {
            //CoreData.   ID kullanarak coreData'dan veri çekeceğiz.
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let context = appDelegate.persistentContainer.viewContext
            
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Places")
            let idString = selectedTitleID!.uuidString
            fetchRequest.predicate = NSPredicate(format: "id = %@", idString)
            fetchRequest.returnsObjectsAsFaults = false
            
            do {
                let results = try context.fetch(fetchRequest)
                if results.count > 0 {
                    
                    for result in results as! [NSManagedObject]{
                        if let title = result.value(forKey: "title") as? String{
                            annotationTitle = title
                            if let subtitle = result.value(forKey: "subtitle") as? String {
                                annotationSubtitle = subtitle
                                if let latitude = result.value(forKey: "latitude") as? Double {
                                    annotationLatitude = latitude
                                    if let longitude = result.value(forKey: "longitude") as? Double {
                                        annotationLongitude = longitude
                                        
                                        let annotation = MKPointAnnotation()
                                        annotation.title = annotationTitle
                                        annotation.subtitle = annotationSubtitle
                                        let coordinate = CLLocationCoordinate2D(latitude: annotationLatitude, longitude: annotationLongitude)
                                        annotation.coordinate = coordinate
                                        
                                        mapView.addAnnotation(annotation)
                                        nameText.text = annotationTitle
                                        commentText.text = annotationSubtitle
                                        
                                        //App'i her açtığımda son eklediğim yere gitsin istiyoruz
                                        locationManager.stopUpdatingLocation()
                                        
                                        let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                                        let region = MKCoordinateRegion(center: coordinate, span: span)
                                        mapView.setRegion(region, animated: true)
                                    }
                                }
                            }
                        }
                    }
                }
            }catch {
                print("error")
            }
        }else {
            //Add new data
        }
    }
    
    @objc func selectLocation(gestureRecognizer:UILongPressGestureRecognizer){
        
        //dokunma işlemi başladıysa dokunma noktaları alacağız.
        if gestureRecognizer.state == .began {
            let touchedPoint = gestureRecognizer.location(in: self.mapView)
            let touchedCoordinates = mapView.convert(touchedPoint, toCoordinateFrom: self.mapView)//dokunulan noktayı koordinata çeviricem
            
            //Veriyi kaydetmek için aşağıda kullanacağımızdan ötürü değişkenşi kaydederiz.
            choosenLatitude = touchedCoordinates.latitude
            choosenLongitude = touchedCoordinates.longitude
            
            let annotation = MKPointAnnotation()//pin oluşturma
            
            annotation.coordinate = touchedCoordinates
            annotation.title = nameText.text
            annotation.subtitle = commentText.text
            self.mapView.addAnnotation(annotation)
        }
        
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if selectedTitle == "" {
            let location = CLLocationCoordinate2D(latitude: locations[0].coordinate.latitude, longitude: locations[0].coordinate.longitude)
            let span = MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1) //Zoomlama değeri.
            let region = MKCoordinateRegion(center: location, span: span)
            
            mapView.setRegion(region, animated: true)
        } else {
            
        }
        
        
        //Paris Charles de Gaulle Airport alanına gittim. Koordinatları 49.01061932084368, 2.55105927997388
        //Simulatorde Custom Location ile bu verileri gireriz.
    }
    
    
    //Burada yazzdığımız kodlar şu anlama geliyor. Pin üzerine tıkladığında veriler geliyor ekrana. Bu verileri kulanarak navigasyon çağrısında bulunacağız.
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        if annotation is MKUserLocation {
            return nil
        }
        
        let reuseID = "myAnnotation"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier:reuseID) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseID)
            pinView?.canShowCallout = true
            pinView?.tintColor = UIColor.blue
            
            let button = UIButton(type: UIButton.ButtonType.detailDisclosure)
            pinView?.rightCalloutAccessoryView = button
        } else {
            pinView?.annotation = annotation
        }
        
        return pinView
    }
    
    //Yukarıda yazdığımız koda ek olarak ekleriz. information bilgisindeki İ harfine tıklayınca içine gireriz.
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if selectedTitle != "" {
            
            let requestLocation = CLLocation(latitude: annotationLatitude, longitude: annotationLongitude)
            CLGeocoder().reverseGeocodeLocation(requestLocation) { (placemarks, error) in
                //closure'ı ayarladık.
                
                if let placemark = placemarks {
                    if placemark.count > 0 {
                        let newPlacemark = MKPlacemark(placemark: (placemark[0]))
                        let item = MKMapItem(placemark: newPlacemark)
                        item.name = self.annotationTitle
                        
                        let launchOptions = [MKLaunchOptionsDirectionsModeKey:MKLaunchOptionsDirectionsModeDriving]
                        item.openInMaps(launchOptions: launchOptions)
                    }
                }
                
                
            }
        }
    }
    

    @IBAction func saveButtonClicked(_ sender: Any) {
        //kayıt işlemi
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        let newPlace = NSEntityDescription.insertNewObject(forEntityName: "Places", into: context)
        newPlace.setValue(nameText.text, forKey: "title")
        newPlace.setValue(commentText.text, forKey: "subtitle")
        newPlace.setValue(choosenLatitude, forKey: "latitude")
        newPlace.setValue(choosenLongitude, forKey: "longitude")
        newPlace.setValue(UUID(), forKey: "id")
        
        do {
            try context.save()
            print("Bence oldu.")
        } catch {
            print("error")
        }
        
        //Yeni yer ekleyince diğer tarafta görmemiz için. Otomatik olarak anasayfaya almasın için yazıyoruz.
        NotificationCenter.default.post(name: NSNotification.Name("newPlace"), object: nil)
        navigationController?.popViewController(animated: true)
        //Bunu viewwillappear'de çağıracağız
        
        
    }
    
    
    
    
}

