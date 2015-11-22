//
//  ViewController.swift
//  Pay It Forward
//
//  Created by Manav Gabhawala on 11/21/15.
//  Copyright © 2015 Manav Gabhawala. All rights reserved.
//

import UIKit

private let clientID = "3192"
private let clientSecret = "hPVdZRv7tXXYVAFuNZZU9ufTWBcq9gJQ"


class ViewController: UIViewController
{
	@IBOutlet var labelAmount: UILabel!
	
	@IBOutlet var webView: UIWebView!
	
	var server : MGNearbyServiceBrowser!
	@IBOutlet var peerPicker: UIPickerView!
	var peers = [MGPeerID]()
		
	
	var amount = 0
	{
		didSet
		{
			dispatch_async(dispatch_get_main_queue(), {
				UIView.animateWithDuration(0.7, delay: 0.0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.0, options: .CurveEaseInOut, animations: {
						self.labelAmount.contentScaleFactor = 1.5

					}, completion: { completed in
						self.labelAmount.text = "\(self.amount)"
				})
				UIView.animateWithDuration(1.0, delay: 0.5, usingSpringWithDamping: 0.8, initialSpringVelocity: 1.0, options: .CurveEaseInOut, animations: {
					self.labelAmount.contentScaleFactor = 1.0
					
					}, completion: nil)
			})
		}
	}
	
	var accessToken: String!
	var username = ""
	var displayName = ""
	
	override func viewDidLoad()
	{
		super.viewDidLoad()
		// Do any additional setup after loading the view, typically from a nib.
		webView.hidden = true
		
		guard let accessTok = NSUserDefaults.standardUserDefaults().stringForKey("access_token")
		else
		{
			showWebView()
			return
		}
		self.accessToken = accessTok
		username = NSUserDefaults.standardUserDefaults().stringForKey("username") ?? ""
		displayName = NSUserDefaults.standardUserDefaults().stringForKey("display_name") ?? ""
		afterVenmoLogin()
	}
	
	
	func showWebView()
	{
		let url = NSURL(string: "https://api.venmo.com/v1/oauth/authorize?client_id=\(clientID)&scope=make_payments%20access_profile&response_type=code")!
		webView.hidden = false
		let request = NSURLRequest(URL: url)
		webView?.delegate = self
		webView?.loadRequest(request)
		webView?.scalesPageToFit = true
//		let topConstraint = NSLayoutConstraint(item: webView!, attribute: .Top, relatedBy: .Equal, toItem: view, attribute: .Top, multiplier: 1.0, constant: 0.0)
//		let leftConstraint = NSLayoutConstraint(item: webView!, attribute: .Left, relatedBy: .Equal, toItem: view, attribute: .Left, multiplier: 1.0, constant: 0.0)
//		let bottomConstraint = NSLayoutConstraint(item: webView!, attribute: .Bottom, relatedBy: .Equal, toItem: view, attribute: .Bottom, multiplier: 1.0, constant: 0.0)
//		let rightConstraint = NSLayoutConstraint(item: webView!, attribute: .Right, relatedBy: .Equal, toItem: view, attribute: .Right, multiplier: 1.0, constant: 0.0)
//		view.addConstraints([topConstraint, bottomConstraint, leftConstraint, rightConstraint])
//		view.addSubview(webView!)
	}
	
	func afterVenmoLogin()
	{
		server = MGNearbyServiceBrowser(peer: MGPeerID(displayName: UIDevice.currentDevice().name), serviceType: "pay-it-forward", venmoDelegate: self)
		server.delegate = self
		server.startBrowsingForPeers()
		peerPicker.delegate = self
		peerPicker.dataSource = self
		
		amount = 0
		NSNotificationCenter.defaultCenter().addObserver(self, selector: "didRecievePoseChange:", name: TLMMyoDidReceivePoseChangedNotification, object: nil)
		NSNotificationCenter.defaultCenter().addObserver(self, selector: "didConnectToMyo:", name: TLMHubDidConnectDeviceNotification, object: nil)

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
			//TODO: submit the amount to venmo
			guard amount > 0
			else
			{
				break
			}
			guard peers.count > 0
			else
			{
				break
			}
			do
			{
				try server.makePayment(peers[peerPicker.selectedRowInComponent(0)], amount: amount)
			}
			catch
			{
				print(error)
				break
			}
		case .FingersSpread:
			device?.vibrateWithLength(TLMVibrationLength.Medium)
			MGDebugLog("Fingers Spread")
			//decrement by 1
			amount = max(0,amount - 1)
		case .Fist:
			MGDebugLog("Fist")
			device?.vibrateWithLength(TLMVibrationLength.Medium)
			//increment by 1
			++amount;
			case .Rest:
			MGDebugLog("Rest")
			//no change
		case .WaveIn:
			MGDebugLog("Wave in")
			device?.vibrateWithLength(TLMVibrationLength.Medium)
			//increment by 10
			amount = amount + 10;
		case .WaveOut:
			MGDebugLog("Wave out")
			device?.vibrateWithLength(TLMVibrationLength.Medium)
			//derement by 10
			amount = max(0,amount - 10)
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
		guard self.accessToken != nil && !self.accessToken.isEmpty
		else { return }
		let vc = TLMSettingsViewController()
		navigationController?.pushViewController(vc, animated: true)
	}
}

extension ViewController : VenmoDelegate
{
	func makePaymentWithAmount(amount: Int, toUser username: String, displayName: String)
	{
		let newPayment = Payment(username: username, displayName: displayName, amount: amount)
		if UIApplication.sharedApplication().applicationState == .Active
		{
			let alert = UIAlertController(title: "New Payment", message: "Complete payment to \(displayName) of $\(amount).00?", preferredStyle: .Alert)
			alert.addAction(UIAlertAction(title: "Decline", style: .Destructive, handler: nil))
			alert.addAction(UIAlertAction(title: "Accept", style: .Default, handler: { (action) -> Void in
				processPayment(newPayment)
			}))
			presentViewController(alert, animated: true, completion: nil)
		}
		else
		{
			let notification = UILocalNotification()
			notification.category = "payment"
			
			if #available(iOS 8.2, *) {
				notification.alertTitle = "New Payment"
			} else {
				// Fallback on earlier versions
			}
			notification.alertBody = "Complete payment to \(displayName) of $\(amount).00?"
			
			let id = NSUUID().UUIDString
			payment_queue[id] = newPayment
			notification.userInfo = ["id": id]
			
			UIApplication.sharedApplication().scheduleLocalNotification(notification)
		}
	}
	
	func paymentAttemptFailed()
	{
		let notification = UILocalNotification()
		notification.category = nil
		notification.hasAction = false
		if #available(iOS 8.2, *) {
		    notification.alertTitle = "Payment Failed"
		} else {
		    // Fallback on earlier versions
		}
		notification.alertBody = "Something went wrong and the payment failed."
		UIApplication.sharedApplication().scheduleLocalNotification(notification)
		
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
	func pickerView(pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString?
	{
		let str : String
		if peers.count == 0
		{
			str = "No Available Peers"
		}
		else
		{
			str = peers[row].displayName
		}
		let string = NSAttributedString(string: str, attributes: [NSForegroundColorAttributeName: UIColor.whiteColor()])
		return string
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
extension ViewController : UIWebViewDelegate
{
	func webView(webView: UIWebView, shouldStartLoadWithRequest request: NSURLRequest, navigationType: UIWebViewNavigationType) -> Bool
	{
		let URLString = request.URL!.absoluteString
		guard URLString.rangeOfString("localhost") != nil
		else
		{
			return true
		}
		guard let index = URLString.rangeOfString("code=")
		else { fatalError() }
		let code = URLString.substringFromIndex(index.endIndex)
		
		let url = NSURL(string: "https://api.venmo.com/v1/oauth/access_token")!
		let request = NSMutableURLRequest(URL: url)
		
		request.HTTPMethod = "POST"
		request.HTTPBody = try? NSJSONSerialization.dataWithJSONObject(["client_id": clientID, "client_secret": clientSecret, "code": code], options: [])
		request.addValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
		
		let task = NSURLSession.sharedSession().dataTaskWithRequest(request) { (data, response, error) -> Void in
			guard let data = data where error == nil
				else {
					print(error?.localizedDescription)
					fatalError()
				}
			guard let json = try? NSJSONSerialization.JSONObjectWithData(data, options: []), let access_token = json["access_token"] as? String, let user_dictionary = json["user"] as? [String:AnyObject], let userName = user_dictionary["id"] as? String, let displayName = user_dictionary["display_name"] as? String
				else {
					fatalError()
				}
			self.accessToken = access_token
			self.username = userName
			self.displayName = displayName
			
			NSUserDefaults.standardUserDefaults().setObject(self.accessToken, forKey: "access_token")
			NSUserDefaults.standardUserDefaults().setObject(self.username, forKey: "username")
			NSUserDefaults.standardUserDefaults().setObject(self.displayName, forKey: "display_name")
			dispatch_async(dispatch_get_main_queue(), {
				webView.hidden = true
				self.afterVenmoLogin()
			})
		}
		task.resume()
		return false
	}
}
