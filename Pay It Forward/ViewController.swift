//
//  ViewController.swift
//  Pay It Forward
//
//  Created by Manav Gabhawala on 11/21/15.
//  Copyright © 2015 Manav Gabhawala. All rights reserved.
//

import UIKit

class ViewController: UIViewController
{
	private let token = "ba39572d4b33b957f645f15062c7a604a76a944c2a56ed20abede056e3c46718"
	
	var server : MGNearbyServiceBrowser!
	@IBOutlet var peerPicker: UIPickerView!
	var peers = [MGPeerID]()
	override func viewDidLoad()
	{
		super.viewDidLoad()
		// Do any additional setup after loading the view, typically from a nib.
		server = MGNearbyServiceBrowser(peer: MGPeerID(displayName: UIDevice.currentDevice().name), serviceType: "pay-it-forward", venmoDelegate: self)
		server.delegate = self
		server.startBrowsingForPeers()
		peerPicker.delegate = self
		peerPicker.dataSource = self
	}
	deinit
	{
		server?.stopBrowsingForPeers()
	}
	
	override func didReceiveMemoryWarning()
	{
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
}
extension ViewController : MGNearbyServiceBrowserDelegate
{
	func browser(browser: MGNearbyServiceBrowser, foundPeer peerID: MGPeerID)
	{
		peers.append(peerID)
		peerPicker.reloadComponent(0)
	}
	func browser(browser: MGNearbyServiceBrowser, lostPeer peerID: MGPeerID)
	{
		peers.removeElement(peerID)
		peerPicker.reloadComponent(0)
	}
}
extension ViewController : VenmoDelegate
{
	var username: String { return "" }
	var displayName: String { return "" }
	
	func makePaymentWithAmount(amount: Int, toUser username: String, displayName: String)
	{
		
	}
	
	func paymentAttemptFailed()
	{
		
	}

}
extension ViewController: UIPickerViewDataSource, UIPickerViewDelegate
{
	func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int
	{
		return 1
	}
	func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int
	{
		return peers.count == 0 ? 1 : peers.count
	}
	
	func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String?
	{
		guard peers.count > 0
		else
		{
			return "No Available Peers"
		}
		return peers[row].displayName
	}
}