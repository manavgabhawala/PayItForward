//
//  AppDelegate.swift
//  Pay It Forward
//
//  Created by Manav Gabhawala on 11/21/15.
//  Copyright © 2015 Manav Gabhawala. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

	var window: UIWindow?


	func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
		// Override point for customization after application launch.
		TLMHub.sharedHub()
		TLMHub.sharedHub().lockingPolicy = .None
		TLMHub.sharedHub().shouldNotifyInBackground = true
		
//		NSUserDefaults.standardUserDefaults().removeObjectForKey("access_token")
//		NSUserDefaults.standardUserDefaults().removeObjectForKey("username")
//		NSUserDefaults.standardUserDefaults().removeObjectForKey("display_name")
		
		let types = UIUserNotificationType.Badge.union(.Alert).union(.Sound)
		let category = UIMutableUserNotificationCategory()
		category.identifier = "payment"
		let accept = UIMutableUserNotificationAction()
		accept.title = "Accept"
		accept.identifier = "accept"
		accept.activationMode = .Foreground
		accept.destructive = false
		accept.authenticationRequired = true
		
		let decline = UIMutableUserNotificationAction()
		decline.title = "Decline"
		decline.identifier = "decline"
		decline.activationMode = .Background
		decline.destructive = true
		decline.authenticationRequired = false
		
		category.setActions([accept, decline], forContext: UIUserNotificationActionContext.Default)
		
		let settings = UIUserNotificationSettings(forTypes: types, categories: Set<UIUserNotificationCategory>(arrayLiteral: category))
		
		UIApplication.sharedApplication().registerUserNotificationSettings(settings)
		
		UIApplication.sharedApplication().performSelector("_setApplicationIsOpaque:", withObject: false)
		return true
	}

	func applicationWillResignActive(application: UIApplication) {
		// Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
		// Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
	}

	func applicationDidEnterBackground(application: UIApplication) {
		// Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
		// If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
	}

	func applicationWillEnterForeground(application: UIApplication) {
		// Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
	}

	func applicationDidBecomeActive(application: UIApplication) {
		// Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
	}

	func applicationWillTerminate(application: UIApplication) {
		// Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
	}
	
	func application(application: UIApplication, handleActionWithIdentifier identifier: String?, forLocalNotification notification: UILocalNotification, completionHandler: () -> Void)
	{
		let id = notification.userInfo!["id"] as! String
		let payment = payment_queue[id]!
		payment_queue[id] = nil
		if identifier == "accept"
		{
			processPayment(payment)
		}
	}
}


func processPayment(payment: Payment)
{
	let url = NSURL(string: "https://api.venmo.com/v1/payments")!
	let request = NSMutableURLRequest(URL: url)
	
	request.HTTPMethod = "POST"
	request.HTTPBody = try? NSJSONSerialization.dataWithJSONObject(["access_token": NSUserDefaults.standardUserDefaults().stringForKey("access_token")!, "user_id": payment.username, "note": "payment done by myo armband", "amount": payment.amount, "audience" : "private"],   options: [])
	
	request.addValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
	
	let task = NSURLSession.sharedSession().dataTaskWithRequest(request) { (data, response, error) -> Void in
		guard let data = data where error == nil
			else {
				print(error?.localizedDescription)
				fatalError()
		}
		
		guard let json = try? NSJSONSerialization.JSONObjectWithData(data, options: [])
			else {
				fatalError()
		}
		
		print(json)
	}
	task.resume()
}



