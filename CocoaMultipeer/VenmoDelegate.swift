//
//  VenmoDelegate.swift
//  Pay It Forward
//
//  Created by Manav Gabhawala on 11/21/15.
//  Copyright © 2015 Manav Gabhawala. All rights reserved.
//

import Foundation


public protocol VenmoDelegate : class
{
	var username: String { get }
	var displayName: String { get }
	var imageData: NSData? { get }
	
	func makePaymentWithAmount(amount: Int, toUser username: String, displayName: String)

	func paymentAttemptFailed()
}
