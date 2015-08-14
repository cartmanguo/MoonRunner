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
import CoreData
import CoreLocation
import HealthKit
import MapKit
let DetailSegueName = "RunDetails"

class NewRunViewController: UIViewController{
  var managedObjectContext: NSManagedObjectContext?

  var run: Run!
    var runData:RunData!
    lazy var locationManager:CLLocationManager = {
        var _locationManager = CLLocationManager()
        _locationManager.delegate = self
        _locationManager.desiredAccuracy = kCLLocationAccuracyBest
        _locationManager.activityType = CLActivityType.Fitness
        _locationManager.distanceFilter = 10
        return _locationManager
    }()
    lazy var duration:Int = 0
    lazy var distance:Double = 0
    var updateTimer:NSTimer?
    var locations:[CLLocation] = []
    var startRunning = false
    
    @IBOutlet weak var signalLebel: UILabel!
    @IBOutlet weak var promptLabel: UILabel!
  @IBOutlet weak var timeLabel: UILabel!
  @IBOutlet weak var distanceLabel: UILabel!
  @IBOutlet weak var paceLabel: UILabel!
  @IBOutlet weak var startButton: UIButton!
  @IBOutlet weak var stopButton: UIButton!
    @IBOutlet weak var mapView: MKMapView!

  override func viewWillAppear(animated: Bool) {
    super.viewWillAppear(animated)

    startButton.hidden = false
    promptLabel.hidden = false

    timeLabel.hidden = true
    distanceLabel.hidden = true
    paceLabel.hidden = true
    stopButton.hidden = true
    mapView.hidden = true
    
    
    if CLLocationManager.authorizationStatus() == CLAuthorizationStatus.NotDetermined
    {
        locationManager.requestAlwaysAuthorization()
    }
    locationManager.startUpdatingLocation()

  }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        updateTimer?.invalidate()
    }

  @IBAction func startPressed(sender: AnyObject) {
    startButton.hidden = true
    promptLabel.hidden = true

    timeLabel.hidden = false
    distanceLabel.hidden = false
    paceLabel.hidden = false
    stopButton.hidden = false
    //mapView.hidden = false
    locations.removeAll(keepCapacity: false)
    updateTimer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: "update", userInfo: nil, repeats: true)
    startRunning = true
  }
    
    func update()
    {
        duration++
        let hkSecondsQuantity = HKQuantity(unit: HKUnit.secondUnit(), doubleValue: Double(duration))
        timeLabel.text = "Time: " + hkSecondsQuantity.description
        
        let hkDistanceQuantity = HKQuantity(unit: HKUnit.meterUnit(), doubleValue: distance)
        distanceLabel.text = "Distance: " + hkDistanceQuantity.description
        
        let paceUnit = HKUnit.secondUnit().unitDividedByUnit(HKUnit.meterUnit())
        let pace = distance/Double(duration)
        let hkPaceQuantity = HKQuantity(unit: paceUnit, doubleValue: pace)
        paceLabel.text = "Pace: " + hkPaceQuantity.description
    }

  @IBAction func stopPressed(sender: AnyObject) {
    let actionSheet = UIActionSheet(title: "Run Stopped", delegate: self, cancelButtonTitle: "Cancel", destructiveButtonTitle: nil, otherButtonTitles: "Save", "Discard")
    actionSheet.actionSheetStyle = .Default
    actionSheet.showInView(view)
  }

  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    if let detailViewController = segue.destinationViewController as? DetailViewController {
      detailViewController.run = run
        detailViewController.runData = runData
    }
  }
}

extension NewRunViewController:CLLocationManagerDelegate
{
    func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!) {
        let latest = locations.last as! CLLocation
        if (latest.horizontalAccuracy < 0)
        {
            // No Signal
            println("no sig")
            signalLebel.text = "no"
        }
        else if (latest.horizontalAccuracy > 163)
        {
            // Poor Signal
            println("poor sig")
            signalLebel.text = "poor"
        }
        else if (latest.horizontalAccuracy > 48)
        {
            // Average Signal
            println("ave sig")
            signalLebel.text = "ave"
        }
        else
        {
            // Full Signal
            println("full sig")
            signalLebel.text = "full"
        }
        if startRunning
        {
            for location in locations as! [CLLocation]
            {
                if self.locations.count > 0
                {
                    distance += location.distanceFromLocation(self.locations.last)
                    var coords = [CLLocationCoordinate2D]()
                    coords.append(self.locations.last!.coordinate)
                    coords.append(location.coordinate)
                    
                    let region = MKCoordinateRegionMakeWithDistance(location.coordinate, 500, 500)
//                    mapView.setRegion(region, animated: true)
//                    
//                    mapView.addOverlay(MKPolyline(coordinates: &coords, count: coords.count))
                }
                self.locations.append(location)
            }
        }
    }
}

extension NewRunViewController: MKMapViewDelegate
{
    func mapView(mapView: MKMapView!, rendererForOverlay overlay: MKOverlay!) -> MKOverlayRenderer! {
        if !overlay.isKindOfClass(MKPolyline) {
            return nil
        }
        
        let polyline = overlay as! MKPolyline
        let renderer = MKPolylineRenderer(polyline: polyline)
        renderer.strokeColor = UIColor.blueColor()
        renderer.lineWidth = 3
        return renderer
    }
}

// MARK: UIActionSheetDelegate
extension NewRunViewController: UIActionSheetDelegate {
  func actionSheet(actionSheet: UIActionSheet, clickedButtonAtIndex buttonIndex: Int) {
    //save
    if buttonIndex == 1 {
        saveRun()
      performSegueWithIdentifier(DetailSegueName, sender: nil)
    }
      //discard
    else if buttonIndex == 2 {
      navigationController?.popToRootViewControllerAnimated(true)
    }
  }
    
    func saveRun()
    {
        let run = NSEntityDescription.insertNewObjectForEntityForName("Run", inManagedObjectContext: managedObjectContext!) as! Run
        run.distance = distance
        run.duration = NSNumber(integer: duration)
        run.timestamp = NSDate()
        
        var savedLocations = [Location]()
        for location in locations {
            let savedLocation = NSEntityDescription.insertNewObjectForEntityForName("Location",
                inManagedObjectContext: managedObjectContext!) as! Location
            savedLocation.timestamp = location.timestamp
            savedLocation.latitude = location.coordinate.latitude
            savedLocation.longitude = location.coordinate.longitude
            savedLocations.append(savedLocation)
        }
        run.locations = NSOrderedSet(array: savedLocations)
        self.run = run
        var err:NSError?
        let success = managedObjectContext?.save(&err)
        if success == false
        {
            NSLog("%@", "failed")
        }
        
        //realm
        let runObj = RunData()
        for location in locations {
            let locations = Locations()
            locations.latitude = location.coordinate.latitude
            locations.longitude = location.coordinate.longitude
            locations.timestamp = location.timestamp
            runObj.locations.addObject(locations)
        }

        runObj.duration = duration
        runObj.distance = CGFloat(distance)
        runObj.date = NSDate(timeIntervalSinceNow: 0)
        runObj.note = "hello"
        runObj.pace = 6.3
        self.runData = runObj
        RunDataManager.sharedInstance.saveRunData(runObj)
    }
}
