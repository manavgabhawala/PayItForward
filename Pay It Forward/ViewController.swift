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
			let controller = storyboard!.instantiateViewControllerWithIdentifier("loginViewController")
			controller.modalPresentationStyle = .FormSheet
			presentViewController(controller, animated: true, completion: nil)
			return
		}
	}
	override func didReceiveMemoryWarning()
	{
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
}

