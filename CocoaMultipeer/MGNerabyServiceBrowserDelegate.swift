//
//  MgNerabyServiceBrowserDelegate.swift
//  Pay It Forward
//
//  Created by Manav Gabhawala on 11/21/15.
//  Copyright © 2015 Manav Gabhawala. All rights reserved.
//

import Foundation


/// The MGNearbyServiceBrowserDelegate protocol defines methods that a MGNearbyServiceBrowser object’s delegate can implement to handle browser-related and invitation events. Since all activity is asynchronous in nature, you cannot make any assumptions of the thread on which the delegate's methods will be called.
public protocol MGNearbyServiceBrowserDelegate : class
{
	/// The browser object that failed to start browsing.
	/// - Parameter browser: The browser object that failed to start browsing.
	/// - Parameter error: An error object indicating what went wrong.
	func browser(browser: MGNearbyServiceBrowser, didNotStartBrowsingForPeers error: [String: NSNumber])
	
	///  The browser object that started browsing. Track this property if you passed nil to the local peer ID's name. The assigned name will now be available through the `myPeerID` property of the browser.
	///
	///  - Parameter browser: The browser object that started browsing and who resolved the local peer's name.
	///
	func browserDidStartSuccessfully(browser: MGNearbyServiceBrowser)
	
	/// Called whenever the browser object stops searching for nearby services. Use this method call to delete the cache and clear any saved state about browsers so that the user does not see duplicate services when actually they all point to the same one.
	///
	///  - parameter browser: The browser object that stopped.
	///
	func browserStoppedSearching(browser: MGNearbyServiceBrowser)
	
	
	/// Called when a nearby peer is found. The peer ID provided to this delegate method can be used to invite the nearby peer to join a session.
	/// - Parameter browser: The browser object that found the nearby peer.
	/// - Parameter peerID: The unique ID of the peer that was found.
	/// - Parameter info: The info dictionary advertised by the discovered peer. For more information on the contents of this dictionary, see the documentation for `initWithPeer:discoveryInfo:serviceType:` in `MGNearbyServiceAdvertiser` Class Reference.
	func browser(browser: MGNearbyServiceBrowser, foundPeer peerID: MGPeerID)
	
	/// Called when a nearby peer is lost. This callback informs your app that invitations can no longer be sent to a peer, and that your app should remove that peer from its user interface.
	/// - Parameter browser: The browser object that lost the nearby peer.
	/// - Parameter peerID: The unique ID of the nearby peer that was lost returns true if that peer was lost. Call this block for all the peers you own to figure out which ones you lost.
	func browser(browser: MGNearbyServiceBrowser, lostPeer peerID: MGPeerID)

	func peerGenerator() -> LazyCollection<[MGPeerID]>
	
	
	/// Called when a nearby peer's discovery info is updated. The peer has already been discovered and the peer ID provided to this delegate method can be used to invite the nearby peer to join a session.
	/// - Parameter browser: The browser object that updated the nearby peer.
	/// - Parameter peerID: The unique ID of the peer that was updated.
	/// - Parameter info: The info dictionary advertised by the discovered peer. For more information on the contents of this dictionary, see the documentation for `initWithPeer:discoveryInfo:serviceType:` in `MGNearbyServiceAdvertiser` Class Reference.
	func browser(browser: MGNearbyServiceBrowser, didUpdatePeer peerID: MGPeerID, withDiscoveryInfo: [String: String]?)
	
	/// Called when a nearby peer could not be resolved. The peer could not be resolved and you probably cannot connect to this peer. Handle the error appropriately.
	/// - Parameter browser: The browser object that updated the nearby peer.
	/// - Parameter peerID: The unique ID of the peer that was updated.
	/// - Parameter errorDict: The error dictionary giving reason as to why the peer could not be resolved.
	func browser(browser: MGNearbyServiceBrowser, couldNotResolvePeer peerID: MGPeerID, withError errorDict: [String: NSNumber])
}

public extension MGNearbyServiceBrowserDelegate
{
	func browser(browser: MGNearbyServiceBrowser, didNotStartBrowsingForPeers error: [String: NSNumber]) {}
	
	func browserDidStartSuccessfully(browser: MGNearbyServiceBrowser) {}
	
	func browserStoppedSearching(browser: MGNearbyServiceBrowser) {}
	
	func browser(browser: MGNearbyServiceBrowser, didUpdatePeer peerID: MGPeerID, withDiscoveryInfo: [String: String]?) {}
	
	func browser(browser: MGNearbyServiceBrowser, couldNotResolvePeer peerID: MGPeerID, withError errorDict: [String: NSNumber]) {}
}

