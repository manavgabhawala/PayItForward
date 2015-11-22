//
//  Payment.swift
//  Pay It Forward
//
//  Created by Manav Gabhawala on 11/21/15.
//  Copyright © 2015 Manav Gabhawala. All rights reserved.
//

import Foundation

var payment_queue = [String : Payment]()

class Payment {
	let username: String
	let displayName: String
	let amount: Int
	
	init (username: String, displayName: String, amount: Int)
	{
		self.username = username;
		self.displayName = displayName
		self.amount = amount
	}
}