//
//  Server.swift
//  Pay It Forward
//
//  Created by Manav Gabhawala on 11/21/15.
//  Copyright © 2015 Manav Gabhawala. All rights reserved.
//

import Foundation

@objc public class MGNearbyServiceBrowser : NSObject
{
	private let server : NSNetService
	private let browser = NSNetServiceBrowser()
	private let fullServiceType: String
	private var availableServices = [NSNetService : MGPeerID]()
	
	/// The service type to browse for. (read-only)
	public let serviceType : String
	
	/// The local peer ID for this instance. (read-only)
	public let myPeerID : MGPeerID
	
	/// The delegate object that handles browser-related events.
	public weak var delegate: MGNearbyServiceBrowserDelegate?
	
	private let delegateHelper : MGNearbyServiceBrowserHelper
	
	private var pendingInvites = [MGNearbyConnectionResolver]()
	
	private weak var venmoDelegate: VenmoDelegate?
	
	
	/// Initializes the nearby service browser object with the TCP connection protocol.
	/// - Parameter peer: The local peer ID for this instance.
	/// - Parameter discoveryInfo: A dictionary of key-value pairs that are made available to browsers. Each key and value must be an NSString object. This data is advertised using a Bonjour TXT record, encoded according to RFC 6763 (section 6). As a result:
	///  	- The key-value pair must be no longer than 255 bytes (total) when encoded in UTF-8 format with an equals sign (=) between the key and the value.
	///  	- Keys cannot contain an equals sign.
	///  	- For optimal performance, the total size of the keys and values in this dictionary should be no more than about 400 bytes so that the entire advertisement can fit within a single Bluetooth data packet. For details on the maximum allowable length, read Monitoring a Bonjour Service.
	/// - Parameter serviceType: Must be 1–15 characters long. Can contain only ASCII lowercase letters, numbers, and hyphens. This name should be easily distinguished from unrelated services. For example, a Foo app made by Bar company could use the service type `foo-bar`.
	public init(peer myPeerID: MGPeerID, serviceType: String, venmoDelegate: VenmoDelegate)
	{
		self.serviceType = serviceType
		self.myPeerID = myPeerID
		guard serviceType.characters.count >= 1 && serviceType.characters.count <= 15 && serviceType.lowercaseString == serviceType && !serviceType.characters.contains("_")
			else
		{
			fatalError("Service name size must be between 1 and 15 characters, can only contain ASCII lowercase letters, numbers and hyphens. Length recieved: \(serviceType.characters.count). String recieved: \(serviceType)")
		}
		self.fullServiceType = "_\(serviceType)._tcp"
		server = NSNetService(domain: "", type: fullServiceType, name: myPeerID.displayName, port: 0)
		server.includesPeerToPeer = true
		browser.includesPeerToPeer = true
		self.venmoDelegate = venmoDelegate
		delegateHelper = MGNearbyServiceBrowserHelper()
		
		super.init()
		
		delegateHelper.ruler = self
		server.delegate = delegateHelper
		browser.delegate = delegateHelper
	}
	
	/// Starts browsing for peers. After this method is called (until you call `stopBrowsingForPeers`), the framework calls your delegate's `browser:foundPeer:withDiscoveryInfo:` and browser:lostPeer: methods as new peers are found and lost. After starting browsing, other devices can discover your device as a device that it can connect to until you call the stop browsing for peers method. However, if the device accepts a connection from another peer the `stopBrowsingForPeers` method is called automatically.
	public func startBrowsingForPeers()
	{
		server.stop()
		MGDebugLog("Attempting to start server")
		MGLog("Attempting to start server")
		server.startMonitoring()
		server.publishWithOptions(NSNetServiceOptions.ListenForConnections)
	}
	
	/// Stops browsing for peers. This will stop the delegate callbacks for discovering peers.
	public func stopBrowsingForPeers()
	{
		server.stop()
		browser.stop()
		server.stopMonitoring()
	}
}

// MARK: - NetService Callbacks
extension MGNearbyServiceBrowser
{
	private func netServiceDidPublish(sender: NSNetService)
	{
		assert(sender === server)
		MGLog("Server started")
		MGDebugLog("Server started and resolved name to \(sender.name)")
		myPeerID.name = sender.name
		browser.stop()
		MGDebugLog("Attempting to browse for nearby devices")
		browser.searchForServicesOfType(fullServiceType, inDomain: "")
		delegate?.browserDidStartSuccessfully?(self)
	}
	private func netService(sender: NSNetService, didNotPublish errorDict: [String : NSNumber])
	{
		assert(sender === server)
		MGLog("Server could not start")
		MGDebugLog("Server could not start with error \(errorDict)")
		delegate?.browser?(self, didNotStartBrowsingForPeers: errorDict)
	}
	private func netServiceDidStop(sender: NSNetService)
	{
		guard sender === server
			else
		{
			return
		}
		MGDebugLog("Server stopped")
		delegate?.browserStoppedSearching?(self)
	}
	
	
	private func netService(sender: NSNetService, didAcceptConnectionWithInputStream inputStream: NSInputStream, outputStream: NSOutputStream)
	{
		stopBrowsingForPeers()
		let newInvite = MGNearbyConnectionResolver(ruler: self, inputStream: inputStream, outputStream: outputStream, venmoDelegate: venmoDelegate)
		pendingInvites.append(newInvite)
	}
	
	public func makePayment(peer: MGPeerID, amount: Int) throws
	{
		var serviceToSend: NSNetService? = nil
		for service in availableServices
		{
			if peer == service.1
			{
				serviceToSend = service.0
				break
			}
		}
		guard let service = serviceToSend
		else
		{
			throw MultipeerError.PeerNotFound
		}
		
		var input : NSInputStream?
		var output : NSOutputStream?
		let status = service.getInputStream(&input, outputStream: &output)
		guard status && input != nil && output != nil
		else
		{
			throw MultipeerError.ConnectionAttemptFailed
		}
		
		let newInvite = MGNearbyConnectionResolver(ruler: self, inputStream: input!, outputStream: output!, remotePeer: peer, amountToPay: amount, venmoDelegate: venmoDelegate)
		pendingInvites.append(newInvite)
		MGLog("Inviting new peer to session")
		MGDebugLog("Inviting new peer \(peer)")
		delegate?.browser(self, lostPeer: availableServices.removeValueForKey(service)!)
	}
}

// MARK: - Browser Callbacks
extension MGNearbyServiceBrowser
{
	private func netServiceBrowser(browser: NSNetServiceBrowser, didNotSearch errorDict: [String : NSNumber])
	{
		assert(browser === self.browser)
		MGLog("Browser error. Could not start.")
		MGDebugLog("Browser could not start with error \(errorDict)")
		delegate?.browser?(self, didNotStartBrowsingForPeers: errorDict)
	}
	
	private func netServiceBrowser(browser: NSNetServiceBrowser, didFindService service: NSNetService, moreComing: Bool)
	{
		assert(browser === self.browser)
		guard service != server && service.name != server.name
		else
		{
			MGDebugLog("Found self with name \(service.name)")
			return
		}
		guard availableServices[service] == nil
		else
		{
			return
		}
		MGLog("Found new peer \(service.name)")
		MGDebugLog("Found new peer \(service.name)")
		let peer = MGPeerID(displayName: service.name)
		availableServices[service] = peer
		delegate?.browser(self, foundPeer: peer)
	}
	
	private func netServiceBrowser(browser: NSNetServiceBrowser, didRemoveService service: NSNetService, moreComing: Bool)
	{
		assert(browser === self.browser)
		guard let peer = availableServices[service]
			else
		{
			return
		}
		MGLog("Lost peer \(service.name)")
		MGDebugLog("Browser lost peer \(service.name) on port \(service.port) and host \(service.hostName)")
		availableServices.removeValueForKey(service)
		delegate?.browser(self, lostPeer: peer)
	}
}

// MARK: - CustomStringConvertible
extension MGNearbyServiceBrowser
{
	public override var description : String { return "Browser for peer \(myPeerID). Searching for services named \(serviceType)" }
}

// MARK: -
// MARK: - NetServiceHelper
/// This class is a helper to handle delegate callbacks privately.
@objc private class MGNearbyServiceBrowserHelper : NSObject
{
	weak var ruler: MGNearbyServiceBrowser?
	var openStreamsCount = 0
	var remotePeer: MGPeerID?
	var inputStream: NSInputStream?
	var outputStream: NSOutputStream?
}
// MARK: - NSNetServiceBrowserDelegate
extension MGNearbyServiceBrowserHelper : NSNetServiceBrowserDelegate
{
	@objc func netServiceBrowserDidStopSearch(browser: NSNetServiceBrowser)
	{
		MGDebugLog("Browser stopped searching for nearby devices.")
	}
	@objc private func netServiceBrowserWillSearch(browser: NSNetServiceBrowser)
	{
		MGDebugLog("Browser started searching for nearby devices")
	}
	@objc func netServiceBrowser(browser: NSNetServiceBrowser, didNotSearch errorDict: [String : NSNumber])
	{
		ruler?.netServiceBrowser(browser, didNotSearch: errorDict)
	}
	@objc func netServiceBrowser(browser: NSNetServiceBrowser, didFindService service: NSNetService, moreComing: Bool)
	{
		ruler?.netServiceBrowser(browser, didFindService: service, moreComing: moreComing)
	}
	@objc func netServiceBrowser(browser: NSNetServiceBrowser, didRemoveService service: NSNetService, moreComing: Bool)
	{
		ruler?.netServiceBrowser(browser, didRemoveService: service, moreComing: moreComing)
	}
}
// MARK: - NSNetServiceDelegate
extension MGNearbyServiceBrowserHelper : NSNetServiceDelegate
{
	@objc func netServiceDidPublish(sender: NSNetService)
	{
		ruler?.netServiceDidPublish(sender)
	}
	@objc func netService(sender: NSNetService, didNotPublish errorDict: [String : NSNumber])
	{
		ruler?.netService(sender, didNotPublish: errorDict)
	}
	@objc func netServiceDidStop(sender: NSNetService)
	{
		ruler?.netServiceDidStop(sender)
	}
	@objc func netService(sender: NSNetService, didAcceptConnectionWithInputStream inputStream: NSInputStream, outputStream: NSOutputStream)
	{
		ruler?.netService(sender, didAcceptConnectionWithInputStream: inputStream, outputStream: outputStream)
	}
}

// MARK: -
// MARK: - Connection Resolution Helper
@objc private class MGNearbyConnectionResolver: NSObject
{
	var openStreamsCount = 0
	
	var remotePeer: MGPeerID?
	
	var inputStream: NSInputStream
	var outputStream: NSOutputStream
	
	weak var ruler: MGNearbyServiceBrowser?
	
	let writeLock = NSCondition()
	
	private let amountToPay : Int?
	private weak var venmoDelegate: VenmoDelegate?

	private init(ruler: MGNearbyServiceBrowser, inputStream: NSInputStream, outputStream: NSOutputStream, venmoDelegate: VenmoDelegate?)
	{
		self.ruler = ruler
		self.inputStream = inputStream
		self.outputStream = outputStream
		self.venmoDelegate = venmoDelegate
		self.amountToPay = nil
		super.init()
		setup()
	}
	
	private init(ruler: MGNearbyServiceBrowser, inputStream: NSInputStream, outputStream: NSOutputStream, remotePeer: MGPeerID, amountToPay amount: Int, venmoDelegate: VenmoDelegate?)
	{
		self.ruler = ruler
		self.outputStream = outputStream
		self.inputStream = inputStream
		self.remotePeer = remotePeer
		self.amountToPay = amount
		self.venmoDelegate = venmoDelegate
		super.init()
		setup()
	}
	
	private func setup()
	{
		self.inputStream.delegate = self
		self.outputStream.delegate = self
		
		self.inputStream.scheduleInRunLoop(NSRunLoop.mainRunLoop(), forMode: NSDefaultRunLoopMode)
		self.outputStream.scheduleInRunLoop(NSRunLoop.mainRunLoop(), forMode: NSDefaultRunLoopMode)
		
		self.inputStream.open()
		self.outputStream.open()
	}
	
}
// MARK: - NSStreamDelegate
extension MGNearbyConnectionResolver : NSStreamDelegate
{
	@objc private func stream(aStream: NSStream, handleEvent eventCode: NSStreamEvent)
	{
		switch eventCode
		{
		case NSStreamEvent.OpenCompleted:
			MGLog("Opened new stream")
			MGDebugLog("Opened new stream")
			++openStreamsCount
			guard openStreamsCount == 2
			else
			{
				break
			}
			MGLog("Both streams opened.")
			MGLog("Opened all streams sending handshake")
			MGDebugLog("Opened all streams sending handshake")
			sendHandshake()
			break
		case NSStreamEvent.HasBytesAvailable:
			guard let input = aStream as? NSInputStream
			else
			{
				fatalError("Expected only input streams to have bytes avaialble")
			}
			// TODO: Accept input data...
			parseJSON(readDataFromStream(input))
			break
		case NSStreamEvent.HasSpaceAvailable:
			MGDebugLog("Stream has space available to write data.")
			self.writeLock.signal()
			break
		case NSStreamEvent.ErrorOccurred, NSStreamEvent.EndEncountered:
			MGLog("Stream error \(aStream.streamError)")
			MGDebugLog("Stream \(aStream) encountered an error \(aStream.streamError?.localizedDescription) with NSError object \(aStream.streamError) and stream's status is \(aStream.streamStatus.rawValue)")
			closeConnection()
			guard amountToPay != nil else { break }
			self.venmoDelegate?.paymentAttemptFailed()
			break
		case NSStreamEvent.None:
			MGLog("Stream status \(aStream.streamStatus.rawValue)") // Who knows what is happening here.
			MGDebugLog("Stream status \(aStream.streamStatus.rawValue)") // Who knows what is happening here.
			assertionFailure("Debugging a None stream event.")
			break
		default:
			break
		}
	}
	private func closeConnection()
	{
		MGDebugLog("An error occurred closing the connection.")
		self.inputStream.delegate = nil
		self.outputStream.delegate = nil
		self.outputStream.removeFromRunLoop(NSRunLoop.mainRunLoop(), forMode: NSDefaultRunLoopMode)
		self.inputStream.removeFromRunLoop(NSRunLoop.mainRunLoop(), forMode: NSDefaultRunLoopMode)
		self.outputStream.close()
		self.inputStream.close()
		self.ruler?.pendingInvites.removeElement(self)
		self.ruler?.startBrowsingForPeers()
	}
	private func sendSmallDataPacket(data: NSData)
	{
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),  {
			var bytes = [UInt8]()
			bytes.reserveCapacity(data.length)
			var dataBytes = UnsafePointer<UInt8>(data.bytes)
			for _ in 0..<data.length
			{
				bytes.append(dataBytes.memory)
				dataBytes = dataBytes.successor()
			}
			assert(bytes.count == data.length)
			self.writeLock.lock()
			while !self.outputStream.hasSpaceAvailable
			{
				self.writeLock.wait()
			}
			defer { self.writeLock.unlock() }
			let len = self.outputStream.write(bytes, maxLength: data.length)
			guard len > 0
			else
			{
				self.closeConnection()
				guard self.amountToPay != nil else { return }
				self.venmoDelegate?.paymentAttemptFailed()
				return
			}
			if self.outputStream.hasSpaceAvailable
			{
				self.writeLock.broadcast()
			}
		})
	}
	private func sendHandshake()
	{
		["n": venmoDelegate?.displayName ?? "Unknown", "u": venmoDelegate?.username ?? "error"]
		let data = try! NSJSONSerialization.dataWithJSONObject(["n": venmoDelegate?.displayName ?? "Unknown", "u": venmoDelegate?.username ?? "error"], options: [])
		sendSmallDataPacket(data)
	}
	
	private func readDataFromStream(stream: NSInputStream) -> [NSObject: AnyObject]?
	{
		guard stream.hasBytesAvailable && stream.streamStatus != .AtEnd
		else
		{
			return nil
		}
		let data = NSMutableData()
		var bytes = [UInt8]()
		bytes.reserveCapacity(255)
		while stream.hasBytesAvailable
		{
			let len = stream.read(&bytes, maxLength: 255)
			guard len > 0
			else
			{
				break
			}
			data.appendBytes(bytes, length: len)
		}
		return parseData(data)
	}
	private func parseData(data: NSData) -> [NSObject: AnyObject]?
	{
		do
		{
			let JSON = try NSJSONSerialization.JSONObjectWithData(data, options: []) as? [NSObject: AnyObject]
			return JSON
		}
		catch
		{
			self.closeConnection()
			return nil
		}
	}
	private func parseJSON(JSON: [NSObject: AnyObject]?)
	{
		defer { self.closeConnection() }
		guard let JSON = JSON, let displayName = JSON["n"] as? String, let username = JSON["u"] as? String
		else
		{
			guard amountToPay != nil
			else
			{
				return
			}
			venmoDelegate?.paymentAttemptFailed()
			return
		}
		guard let amountToPay = self.amountToPay
		else
		{
			return
		}
		venmoDelegate?.makePaymentWithAmount(amountToPay, toUser: username, displayName: displayName)
	}
}
