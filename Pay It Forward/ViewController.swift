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
	
	@IBOutlet var labelAmount: UILabel!
	
	var server : MGNearbyServiceBrowser!
	@IBOutlet var peerPicker: UIPickerView!
	var peers = [MGPeerID]()
	var amount = 0
	{
		didSet
		{
			labelAmount.text = "$ \(amount)"
		}
	}
	
	
	override func viewDidLoad()
	{
		super.viewDidLoad()
		// Do any additional setup after loading the view, typically from a nib.
		
		server = MGNearbyServiceBrowser(peer: MGPeerID(displayName: UIDevice.currentDevice().name), serviceType: "pay-it-forward", venmoDelegate: self)
		server.delegate = self
		server.startBrowsingForPeers()
		peerPicker.delegate = self
		peerPicker.dataSource = self
		
		amount = 0
		NSNotificationCenter.defaultCenter().addObserver(self, selector: "didRecievePoseChange:", name: TLMMyoDidReceivePoseChangedNotification, object: nil)
		NSNotificationCenter.defaultCenter().addObserver(self, selector: "didConnectToMyo:", name: TLMHubDidConnectDeviceNotification, object: nil)
	}
	override func viewDidAppear(animated: Bool)
	{
		super.viewDidAppear(animated)
		if (TLMHub.sharedHub().myoDevices().count == 0)
		{
			showMyoSettings()
		}
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
	
	func didRecievePoseChange(notification: NSNotification)
	{
		guard let pose = notification.userInfo?[kTLMKeyPose] as? TLMPose
		else
		{
			print("Error casting")
			return
		}
		let device = (TLMHub.sharedHub().myoDevices().first as? TLMMyo)
		switch pose.type
		{
		case .DoubleTap:
			MGDebugLog("Double tap")
			device?.vibrateWithLength(TLMVibrationLength.Short)
			//submit the amount to venmo
		case .FingersSpread:
			MGDebugLog("Fingers Spread")
			//increment by 10 
			amount = amount + 10;
		case .Fist:
			MGDebugLog("Fist")
			device?.vibrateWithLength(TLMVibrationLength.Long)
			//derement by 10
			amount = max(0,amount - 10)
		case .Rest:
			MGDebugLog("Rest")
			//no change
		case .WaveIn:
			MGDebugLog("Wave in")
			device?.vibrateWithLength(TLMVibrationLength.Medium)
			//decrement by 1 
			amount = max(0,amount - 1)
		case .WaveOut:
			MGDebugLog("Wave out")
			device?.vibrateWithLength(TLMVibrationLength.Medium)
			//increment by 1
			++amount;
		case .Unknown:
			MGDebugLog("Unknown")
		}
	}
	func didConnectToMyo(notification: NSNotification)
	{
		if (TLMHub.sharedHub().myoDevices().count > 0)
		{
			navigationController?.popToRootViewControllerAnimated(true)
		}
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
	@IBAction func showMyoSettings(_ : UIBarButtonItem? = nil)
	{
		navigationController?.pushViewController(TLMSettingsViewController(), animated: true)
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
