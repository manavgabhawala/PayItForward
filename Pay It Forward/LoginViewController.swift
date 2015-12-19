//
//  LoginViewController.swift
//  Pay It Forward
//
//  Created by Manav Gabhawala on 12/9/15.
//  Copyright © 2015 Manav Gabhawala. All rights reserved.
//

import UIKit
import CocoaMultipeer

class LoginViewController: UIViewController
{
	@IBOutlet var webView: UIWebView!
	
	override func viewDidLoad()
	{
		webView.delegate = self
		webView.scalesPageToFit = true
	}
	
	override func viewDidAppear(animated: Bool)
	{
		super.viewDidAppear(animated)
		guard !VenmoManager.sharedManager().isLoggedIn
		else
		{
			// There's no logging in to do.
			dismissViewControllerAnimated(true, completion: nil)
			return
		}
		webView.loadRequest(NSURLRequest(URL: NSURL(string: "https://api.venmo.com/v1/oauth/authorize?client_id=\(VenmoManager.clientID)&scope=make_payments%20access_profile&response_type=code")!))
	}
	
	
}
extension LoginViewController : UIWebViewDelegate
{
	func webView(webView: UIWebView, shouldStartLoadWithRequest request: NSURLRequest, navigationType: UIWebViewNavigationType) -> Bool
	{
		guard let URLString = request.URL?.absoluteString where URLString.rangeOfString("localhost") != nil
		else
		{
			return true
		}
		
		guard let index = URLString.rangeOfString("code=")
		else
		{
			// TODO: Check for error in the string.
			return true
		}
		
		let code = URLString.substringFromIndex(index.endIndex) // Extract the code.
		let url = VenmoManager.baseURL.URLByAppendingPathComponent("oauth/access_token")
		let request = NSMutableURLRequest(URL: url)
		
		request.HTTPMethod = "POST"
		request.HTTPBody = try? NSJSONSerialization.dataWithJSONObject(["client_id": VenmoManager.clientID, "client_secret": VenmoManager.clientSecret, "code": code], options: [])
		request.addValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
		
		let task = NSURLSession.sharedSession().dataTaskWithRequest(request) { (data, response, error) -> Void in
			guard let data = data where error == nil
			else
			{
				// TODO: Error handling
				print(error?.localizedDescription)
				assertionFailure()
				return
			}
			do
			{
				try VenmoManager.sharedManager().loginWithData(data)
				// TODO: Dismiss view controller here...
				// Show intro to the app here.
			}
			catch
			{
				// TODO: Error handling
			}
		}
		task.resume()
		return false
	}
}

