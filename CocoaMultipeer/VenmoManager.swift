//
//  VenmoManager.swift
//  Pay It Forward
//
//  Created by Manav Gabhawala on 12/9/15.
//  Copyright © 2015 Manav Gabhawala. All rights reserved.
//

import Foundation

private let _clientID = "3192"
private let _clientSecret = "hPVdZRv7tXXYVAFuNZZU9ufTWBcq9gJQ"
private let accessTokenKey = "venmo_access_token"
private let refreshTokenKey = "venmo_refresh_token"
private let defaults = NSUserDefaults(suiteName: VenmoManager.groupIdentifier)!
private let path = NSFileManager().containerURLForSecurityApplicationGroupIdentifier(VenmoManager.groupIdentifier)!
private let profilePictureFile = "profile_picture"
private let manager = VenmoManager()

public enum VenmoError : ErrorType
{
	case UnknownLoginError
	case VenmoServerLoginError(String)
}

@objc public final class VenmoManager: NSObject
{
	internal static let groupIdentifier = "group.ManavGabhawala.Pay-It-Forward-Shared"
	
	public var isLoggedIn: Bool
	{
		get
		{
			return SSKeychain.passwordForService(accessTokenKey, account: defaults.stringForKey("username") ?? "") != nil
		}
	}
	public var name: String
	{
		get
		{
			assert(isLoggedIn)
			return defaults.stringForKey("name")!
		}
	}
	public var username: String
	{
		get
		{
			assert(isLoggedIn)
			return defaults.stringForKey("username")!
		}
	}
	public var imageData: NSData?
	{
		get
		{
			return NSData(contentsOfURL: path.URLByAppendingPathComponent(profilePictureFile))
		}
	}
	
	public static var clientID: String { return _clientID }
	public static var clientSecret: String { return _clientSecret }
	
	public class func sharedManager() -> VenmoManager
	{
		return manager
	}
	
	public func loginWithData(data: NSData) throws
	{
		guard let dict = (try? NSJSONSerialization.JSONObjectWithData(data, options: [])) as? [String: AnyObject]
		else
		{
			throw VenmoError.UnknownLoginError
		}
		
		guard dict["error"] == nil
		else
		{
			throw VenmoError.VenmoServerLoginError((dict["error"] as! [String: AnyObject])["message"] as? String ?? "An unknown error occurred while logging into Venmo.")
		}
		guard let accessToken = dict["access_token"] as? String, let refreshToken = dict["refresh_token"] as? String, let expiresIn = dict["expires_in"] as? NSTimeInterval, let userData = dict["user"] as? [String: AnyObject]
		else
		{
			throw VenmoError.UnknownLoginError
		}
		let username = userData["username"] as? String ?? "error"
		let name = userData["display_name"] as? String ?? "Unknown"
		if let imageURL = userData["profile_picture_url"] as? String, let URL = NSURL(string: imageURL)
		{
			downloadImage(URL)
		}
		SSKeychain.setPassword(accessToken, forService: accessTokenKey, account: username)
		SSKeychain.setPassword(refreshToken, forService: refreshTokenKey, account: username)
		defaults.setDouble(expiresIn, forKey: "expires_in")
		defaults.setObject(username, forKey: "username")
		defaults.setObject(name, forKey: "name")
	}
	
	private func downloadImage(URL: NSURL)
	{
		defaults.setObject(URL.absoluteString, forKey: "profile_picture")
		NSURLSession.sharedSession().downloadTaskWithURL(URL, completionHandler: { (downloadedFile, response, error) -> Void in
			guard error == nil
			else
			{
				defaults.setObject(URL.absoluteString, forKey: "profile_picture")
				return
			}
			let pathURL = path.URLByAppendingPathComponent(profilePictureFile)
			_ = try? NSFileManager.defaultManager().moveItemAtURL(URL, toURL: pathURL)
		})
	}
	
	func makePaymentWithAmount(amount: Int, toUser username: String, displayName: String)
	{
		
	}
}