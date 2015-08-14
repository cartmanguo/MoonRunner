/*
* Copyright (c) 2015 Razeware LLC
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in
* all copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
* THE SOFTWARE.
*/

import UIKit
import MapKit
import HealthKit
class DetailViewController: UIViewController {
  var run: Run!
    var runData:RunData!
  @IBOutlet weak var mapView: MKMapView!
  @IBOutlet weak var distanceLabel: UILabel!
  @IBOutlet weak var dateLabel: UILabel!
  @IBOutlet weak var timeLabel: UILabel!
  @IBOutlet weak var paceLabel: UILabel!

  override func viewDidLoad() {
    super.viewDidLoad()
    mapView.delegate = self
    configureView()
    loadMap()
  }
    
    func loadMap()
    {
        if runData.locations.count >= 2
        {
            mapView.region = mapRegion()
            let locations = runData.locations
            //        var coordinates = [CLLocationCoordinate2D]()
            //        for var i:UInt = 0;i<locations.count;i++
            //        {
            //            let location = locations[i] as! Locations
            //            let coordinate = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
            //            coordinates.append(coordinate)
            //        }
            let multiColorPolyline = MultiColorPolyline.colorSegmentsFromRunData(runData)
            mapView.addOverlays(multiColorPolyline)
        }
        //mapView.addOverlay(polyline())
    }

  func configureView() {
      let hkDistanceQuantity = HKQuantity(unit: HKUnit.meterUnit(), doubleValue: Double(runData.distance))
        self.distanceLabel.text = "Distance: " + hkDistanceQuantity.description
    
    let hkSecondsQuantity = HKQuantity(unit: HKUnit.secondUnit(), doubleValue: Double(runData.duration))
    self.timeLabel.text = hkSecondsQuantity.description
    let paceUnit = HKUnit.secondUnit().unitDividedByUnit(HKUnit.meterUnit())
    let pace = Double(runData.distance)/Double(runData.duration)
    RunDataManager.sharedInstance.realm.beginWriteTransaction()
    runData.pace = pace
    RunDataManager.sharedInstance.realm.commitWriteTransaction()
    let hkPaceQuantity = HKQuantity(unit: paceUnit, doubleValue: pace)
    self.paceLabel.text = hkPaceQuantity.description
    self.dateLabel.text = runData.date.description
    }
    
    func mapRegion() -> MKCoordinateRegion {
        let initialLoc = runData.locations.firstObject() as! Locations
        
        var minLat = initialLoc.latitude
        var minLng = initialLoc.longitude
        var maxLat = minLat
        var maxLng = minLng
        
        let locations = runData.locations
        for var i:UInt = 0;i < locations.count; i++
        {
            let location = locations[i] as! Locations
            minLat = min(minLat, location.latitude)
            minLng = min(minLng, location.longitude)
            maxLat = max(maxLat, location.latitude)
            maxLng = max(maxLng, location.longitude)
        }
//        
//        for location in locations {
//            minLat = min(minLat, location.latitude.doubleValue)
//            minLng = min(minLng, location.longitude.doubleValue)
//            maxLat = max(maxLat, location.latitude.doubleValue)
//            maxLng = max(maxLng, location.longitude.doubleValue)
//        }
        
        return MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: (minLat + maxLat)/2,
                longitude: (minLng + maxLng)/2),
            span: MKCoordinateSpan(latitudeDelta: (maxLat - minLat)*1.1,
                longitudeDelta: (maxLng - minLng)*1.1))
    }
}

// MARK: - MKMapViewDelegate
extension DetailViewController: MKMapViewDelegate {
    func mapView(mapView: MKMapView!, rendererForOverlay overlay: MKOverlay!) -> MKOverlayRenderer! {
        if !overlay.isKindOfClass(MultiColorPolyline)
        {
            return nil
        }
        let polyLine = overlay as! MultiColorPolyline
        let renderer = MKPolylineRenderer(polyline: polyLine)
        renderer.strokeColor = polyLine.color
        renderer.lineWidth = 4
        return renderer
    }
    
    func polyline()->MKPolyline
    {
        var coordinates = [CLLocationCoordinate2D]()
        let locations = runData.locations
        for var i:UInt = 0;i < locations.count; i++
        {
            let location = locations[i] as! Locations
            let coordinate = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
            coordinates.append(coordinate)
        }
//        for location in locations
//        {
//            let coordinate = CLLocationCoordinate2D(latitude: location.latitude.doubleValue, longitude: location.longitude.doubleValue)
//            coordinates.append(coordinate)
//        }
        let polyline = MKPolyline(coordinates: &coordinates, count: Int(locations.count))
        return polyline
    }
}
