//
//  ViewController.swift
//  Pay It Forward
//
//  Created by Manav Gabhawala on 12/9/15.
//  Copyright © 2015 Manav Gabhawala. All rights reserved.
//

import UIKit
import CocoaMultipeer

class ViewController: UIViewController
{
	
	var server : MGNearbyServiceBrowser!
	
	override func viewDidLoad()
	{
		super.viewDidLoad()
		// Do any additional setup after loading the view, typically from a nib.
	}
	override func viewDidAppear(animated: Bool)
	{
		super.viewDidAppear(animated)
		guard VenmoManager.sharedManager().isLoggedIn
		else
		{
			// TODO: Show splash page with login with venmo button here.
			let controller = storyboard!.instantiateViewControllerWithIdentifier("loginViewController")
			controller.modalPresentationStyle = .FormSheet
			presentViewController(controller, animated: true, completion: nil)
			return
		}
		if server == nil
		{
			server = MGNearbyServiceBrowser(peer: MGPeerID(displayName: VenmoManager.sharedManager().name), serviceType: "pay-it-forward", venmoDelegate: self)
			// server.delegate = self 
			// TODO: Make conformance
		}
		server.startBrowsingForPeers()
	}
	override func didReceiveMemoryWarning()
	{
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
}

extension ViewController : VenmoDelegate
{
	var username: String { return VenmoManager.sharedManager().username }
	var displayName: String { return VenmoManager.sharedManager().name }
	var imageData: NSData? { return VenmoManager.sharedManager().imageData }
	
	func makePaymentWithAmount(amount: Int, toUser username: String, displayName: String)
	{
		VenmoManager.sharedManager().makePaymentWithAmount(amount, toUser: username, displayName: displayName)
		server.startBrowsingForPeers() // Just in case it got stopped.
	}
	
	func paymentAttemptFailed()
	{
		// TODO: Show error.
		server.startBrowsingForPeers() // In case our automatic recovery failed.
	}

}