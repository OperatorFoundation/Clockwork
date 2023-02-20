//
//  ClockworkSpacetime.swift
//
//
//  Created by Dr. Brandon Wiley on 1/8/23.
//

import ArgumentParser
import Foundation

import Gardener

public class ClockworkSpacetime
{
    let parser: any Parser

    public init(parser: any Parser)
    {
        self.parser = parser
    }

    public func generate(source: String, interactionsOutput: String, moduleOutput: String, universeOutput: String) throws
    {
        let sourceURL = URL(fileURLWithPath: source)
        let source = try String(contentsOf: sourceURL)
        let className = try self.parser.findClassName(source)

        let functions = try self.parser.findFunctions(source)

        guard functions.count > 0 else
        {
            return
        }

        let interactionsURL = URL(fileURLWithPath: interactionsOutput)
        let moduleURL = URL(fileURLWithPath: moduleOutput)
        let universeURL = URL(fileURLWithPath: universeOutput)

        try self.generateInteractions(interactionsURL, className, functions)
        try self.generateUniverseExtension(universeURL, className, functions)
        try self.generateModule(moduleURL, className, functions)
    }


    func generateRequestEnumsText(_ functions: [Function]) -> String
    {
        let enums = functions.map { self.generateRequestEnumCase($0) }
        return enums.joined(separator: "\n")
    }

    func generateRequestEnumCase(_ function: Function) -> String
    {
        if function.parameters.isEmpty
        {
            return "    case \(function.name)"
        }
        else
        {
            return "    case \(function.name)(\(function.name.capitalized))"
        }
    }

    func generateResponseEnumsText(_ functions: [Function]) throws -> String
    {
        let enums = try functions.map { try self.generateResponseEnumCase($0) }
        return enums.joined(separator: "\n")
    }

    func generateResponseEnumCase(_ function: Function) throws -> String
    {
        if let returnType = function.returnType
        {
            return "    case \(function.name)(\(returnType))"
        }
        else
        {
            return "    case \(function.name)"
        }
    }

    func generateParameter(_ parameter: FunctionParameter) -> String
    {
        return "\(parameter.name): \(parameter.type)"
    }

    func generateInit(_ parameter: FunctionParameter) -> String
    {
        return "        self.\(parameter.name) = \(parameter.name)"
    }
}

public enum ClockworkSpacetimeError: Error
{
    case sourcesDirectoryDoesNotExist
    case noMatches
    case tooManyMatches
    case badFunctionFormat
    case noOutputDirectory
    case templateNotFound
}
