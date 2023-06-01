//
//  MapLinkController.swift
//  TakeMySigns
//
//  Created by Dane Wilson on 4/25/22.
//

import SwiftUI
import CoreLocation
import MapKit
import UIKit

public class MapLinkController {
  // If you are calling the coordinate from a Model, don't forgot to pass it in the function parenthesis.
  public static func present(in viewController: UIViewController, sourceView: UIView, location: FyreKitLocation) {
    let actionSheet = UIAlertController(title: "Open Location", message: "Choose an app to open direction", preferredStyle: .actionSheet)
    actionSheet.addAction(UIAlertAction(title: "Google Maps", style: .default, handler: { _ in
      // Pass the coordinate inside this URL
      let url = URL(string: "comgooglemaps://?daddr=\(location.latitude), \(location.longitude)&directionsmode=driving&zoom=14&views=traffic")!
      UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }))
    actionSheet.addAction(UIAlertAction(title: "Apple Maps", style: .default, handler: { _ in
      // Pass the coordinate that you want here
      let coordinate = CLLocationCoordinate2DMake(location.latitude, location.longitude)
      let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: coordinate, addressDictionary: nil))
      mapItem.name = "Destination"
      mapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving])
    }))
    actionSheet.popoverPresentationController?.sourceRect = sourceView.bounds
    actionSheet.popoverPresentationController?.sourceView = sourceView
    actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
    viewController.present(actionSheet, animated: true, completion: nil)
  }
}
