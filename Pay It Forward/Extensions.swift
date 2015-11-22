//
//  Extensions.swift
//  Pay It Forward
//
//  Created by Manav Gabhawala on 11/21/15.
//  Copyright © 2015 Manav Gabhawala. All rights reserved.
//

import Foundation


extension Array where Element : Equatable
{
	internal mutating func removeElement(element: Generator.Element)
	{
		self = filter({ $0 != element })
	}
}

/// Change this value to true to get a normal log of the details of the server. If debug log is on normal logging doesn't occur but the debug logging logs all the output that normal log would with more detail. By default this is false.
public var normalLog = false
/// Change this value to true in order to get a detailed log of everything happening under the covers. By default this is true.
public var debugLog = true

internal func MGLog<Item>(item: Item)
{
	guard normalLog && !debugLog
		else
	{
		return
	}
	print(item)
}
internal func MGLog<Item>(item: Item?)
{
	guard normalLog && !debugLog
		else
	{
		return
	}
	print(item)
}

internal func MGDebugLog<Item>(item: Item)
{
	guard debugLog
		else
	{
		return
	}
	debugPrint(item)
}
internal func MGDebugLog<Item>(item: Item?)
{
	guard normalLog
		else
	{
		return
	}
	debugPrint(item)
}
