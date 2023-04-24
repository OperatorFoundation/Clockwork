//
//  ClockworkBase.swift
//
//
//  Created by Dr. Brandon Wiley on 2/19/23.
//

import Foundation

public protocol Parser
{
    init()

    func findImports(_ source: String) throws -> [String]
    func findClassName(_ sourceURL: URL, _ source: String) throws -> String
    func findFunctions(_ source: String) throws -> [Function]
}

public struct Function
{
    let name: String
    let parameters: [FunctionParameter]
    let returnType: String?
    let throwing: Bool
}

public struct FunctionParameter
{
    let name: String
    let type: String
}
