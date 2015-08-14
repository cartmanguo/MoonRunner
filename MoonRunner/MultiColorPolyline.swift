//
//  MultiColorPolyline.swift
//  MoonRunner
//
//  Created by randy on 15/8/14.
//  Copyright (c) 2015年 Zedenem. All rights reserved.
//

import UIKit
import MapKit
class MultiColorPolyline: MKPolyline {
    var color: UIColor?
    private class func allSpeedsFromRunData(runData:RunData)->(speeds:[Double],slowestSpeed:Double,fastestSpeed:Double)
    {
        var speeds = [Double]()
        var fastSpeed = 0.0
        var slowSpeed = DBL_MAX
        let locations = runData.locations
        println("cnt:\(locations.count)")
        for var i:UInt = 0;i < locations.count-1;i++
        {
            println(i)
            let prevLocation = locations[i] as! Locations
            let nxtLocation = locations[i+1] as! Locations
            let previousLocation = CLLocation(latitude: prevLocation.latitude, longitude: prevLocation.longitude)
            let nextLocation = CLLocation(latitude: nxtLocation.latitude, longitude: nxtLocation.longitude)
            let distance = nextLocation.distanceFromLocation(previousLocation)
            let time = nxtLocation.timestamp.timeIntervalSinceDate(prevLocation.timestamp)
            let speed = distance/time
            speeds.append(speed)
            fastSpeed = max(fastSpeed, speed)
            slowSpeed = min(slowSpeed, speed)
        }
        return (speeds,slowSpeed,fastSpeed)
    }
    
    class func colorSegmentsFromRunData(runData:RunData) -> [MultiColorPolyline] {
        var colorSegments = [MultiColorPolyline]()
        
        // RGB for Red (slowest)
        let red   = (r: 1.0, g: 20.0 / 255.0, b: 44.0 / 255.0)
        
        // RGB for Yellow (middle)
        let yellow = (r: 1.0, g: 215.0 / 255.0, b: 0.0)
        
        // RGB for Green (fastest)
        let green  = (r: 0.0, g: 146.0 / 255.0, b: 78.0 / 255.0)
        
        let (speeds, minSpeed, maxSpeed) = allSpeedsFromRunData(runData)
        
        // now knowing the slowest+fastest, we can get mean too
        let meanSpeed = (minSpeed + maxSpeed)/2
        let locations = runData.locations
        for i in 1..<locations.count
        {
            let l1 = locations[i-1] as! Locations
            let l2 = locations[i] as! Locations
            
            var coords = [CLLocationCoordinate2D]()
            
            coords.append(CLLocationCoordinate2D(latitude: l1.latitude, longitude: l1.longitude))
            coords.append(CLLocationCoordinate2D(latitude: l2.latitude, longitude: l2.longitude))
            let idx = Int(i-1)
            let speed = speeds[idx]
            var color = UIColor.blackColor()
            
            if speed < minSpeed { // Between Red & Yellow
                let ratio = (speed - minSpeed) / (meanSpeed - minSpeed)
                let r = CGFloat(red.r + ratio * (yellow.r - red.r))
                let g = CGFloat(red.g + ratio * (yellow.g - red.g))
                let b = CGFloat(red.r + ratio * (yellow.r - red.r))
                color = UIColor(red: r, green: g, blue: b, alpha: 1)
            }
            else { // Between Yellow & Green
                let ratio = (speed - meanSpeed) / (maxSpeed - meanSpeed)
                let r = CGFloat(yellow.r + ratio * (green.r - yellow.r))
                let g = CGFloat(yellow.g + ratio * (green.g - yellow.g))
                let b = CGFloat(yellow.b + ratio * (green.b - yellow.b))
                color = UIColor(red: r, green: g, blue: b, alpha: 1)
            }
            
            let segment = MultiColorPolyline(coordinates: &coords, count: coords.count)
            segment.color = color
            colorSegments.append(segment)
        }
        return colorSegments
    }
}
