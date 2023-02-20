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

    func findClassName(_ source: String) throws -> String
    func findFunctions(_ source: String) throws -> [Function]
    func findFunctionName(_ function: String) throws -> String
    func findParameters(_ function: String) throws -> [FunctionParameter]
    func findFunctionReturnType(_ function: String) throws -> String?
    func findFunctionThrowing(_ function: String) throws -> Bool
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
