//
//  Config.swift
//  
//
//  Created by Dr. Brandon Wiley on 3/1/23.
//

import Foundation

public class ClockworkConfig: Codable
{
    public let batch: Bool
    public let cbor: Bool
    public let source: String
    public let swiftMessages: String?
    public let kotlinMessages: String?
    public let pythonMessages: String?
    public let swiftClient: String?
    public let pythonClient: String?
    public let kotlinClient: String?
    public let swiftServer: String?
    public let pythonServer: String?
    public let kotlinPackage: String?
    public let cMessages: String?
    public let cServer: String?
    public let cppMessages: String?
    public let cppServer: String?
    public let cppModule: String?
    public let cppUniverse: String?
    public let authenticateClient: Bool?

    public init(batch: Bool, cbor: Bool, source: String, swiftMessages: String?, kotlinMessages: String?, pythonMessages: String?, swiftClient: String? = nil, pythonClient: String? = nil, kotlinClient: String? = nil, swiftServer: String? = nil, pythonServer: String? = nil, kotlinPackage: String? = nil, cMessages: String? = nil, cServer: String? = nil, cppMessages: String? = nil, cppServer: String? = nil, cppModule: String? = nil, cppUniverse: String? = nil, authenticateClient: Bool? = nil)
    {
        self.batch = batch
        self.cbor = cbor
        self.source = source
        self.swiftMessages = swiftMessages
        self.kotlinMessages = kotlinMessages
        self.pythonMessages = pythonMessages
        self.swiftClient = swiftClient
        self.pythonClient = pythonClient
        self.kotlinClient = kotlinClient
        self.swiftServer = swiftServer
        self.pythonServer = pythonServer
        self.kotlinPackage = kotlinPackage
        self.cMessages = cMessages
        self.cServer = cServer
        self.cppMessages = cppMessages
        self.cppServer = cppServer
        self.cppModule = cppModule
        self.cppUniverse = cppUniverse
        self.authenticateClient = authenticateClient
    }
}

extension ClockworkConfig
{
    public static func load(url: URL) throws -> ClockworkConfig
    {
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        return try decoder.decode(ClockworkConfig.self, from: data)
    }

    public func save(url: URL) throws
    {
        let encoder = JSONEncoder()
        let data = try encoder.encode(self)
        try data.write(to: url)
    }
}
