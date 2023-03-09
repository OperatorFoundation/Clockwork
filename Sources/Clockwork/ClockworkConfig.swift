//
//  Config.swift
//  
//
//  Created by Dr. Brandon Wiley on 3/1/23.
//

import Foundation

public class ClockworkConfig: Codable
{
    public let source: String
    public let swiftMessages: String?
    public let kotlinMessages: String?
    public let pythonMessages: String?
    public let swiftClient: String?
    public let pythonClient: String?
    public let kotlinClient: String?
    public let swiftServer: String?
    public let pythonServer: String?

    public init(source: String, swiftMessages: String?, kotlinMessages: String?, pythonMessages: String?, swiftClient: String? = nil, pythonClient: String? = nil, kotlinClient: String? = nil, swiftServer: String? = nil, pythonServer: String? = nil)
    {
        self.source = source
        self.swiftMessages = swiftMessages
        self.kotlinMessages = kotlinMessages
        self.pythonMessages = pythonMessages
        self.swiftClient = swiftClient
        self.pythonClient = pythonClient
        self.kotlinClient = kotlinClient
        self.swiftServer = swiftServer
        self.pythonServer = pythonServer
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
