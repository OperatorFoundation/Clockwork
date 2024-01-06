//
//  ExtractedInterface.swift
//
//
//  Created by Dr. Brandon Wiley on 12/30/23.
//

import Foundation

public struct ExtractedInterface: Codable
{
    public let className: String
    public let functions: [Function]

    public init(className: String, functions: [Function])
    {
        self.className = className
        self.functions = functions
    }

    public init(_ input: URL) throws
    {
        let data = try Data(contentsOf: input)
        let decoder = JSONDecoder()
        let result: Self = try decoder.decode(Self.self, from: data)
        self = result
    }

    public func save(_ output: URL) throws
    {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        
        let data = try encoder.encode(self)
        try data.write(to: output)
    }
}
