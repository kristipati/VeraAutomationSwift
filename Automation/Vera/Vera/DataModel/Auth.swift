//
//  Auth.swift
//  Vera
//
//  Created by Scott Gruby on 12/11/14.
//  Copyright (c) 2014 Gruby Solutions. All rights reserved.
//

import Foundation

public class Auth : Deserializable, Printable {
    
    var authToken:String?
    var authSigToken:String?
    var serverAccount:String?
    var account:String?

    public required init(data: [String: AnyObject]) {
        authToken <<< data["Identity"]
        authSigToken <<< data["IdentitySignature"]
        serverAccount <<< data["Server_Account"]
        account <<< data["PK_Account"]
        if (account == nil) {
            var accountNumber: Int?
            accountNumber <<< data["PK_Account"]
            if (accountNumber != nil) {
                account = "\(accountNumber!)"
            }
        }
    }
    
    public var description: String {
        var desc: String = "AuthToken: "
        if authToken != nil {
            desc += authToken!
        }

        desc += "\nAuthSigToken: \n"

        if authSigToken != nil {
            desc += authSigToken!
        }

        desc += "\nServerAccount: \n"
        if serverAccount != nil {
            desc += serverAccount!
        }

        desc += "\nAccount: \n"
        if account != nil {
            desc += account!
        }

        return desc
    }
}