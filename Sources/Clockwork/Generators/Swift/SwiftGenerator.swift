//
//  SwiftGenerator.swift
//  
//
//  Created by Dr. Brandon Wiley on 1/5/23.
//

import ArgumentParser
import Foundation

import Gardener

public class SwiftGenerator
{
    let parser: any Parser

    public init(parser: any Parser)
    {
        self.parser = parser
    }

    func generateImports(_ imports: [String]) -> String
    {
        var allImports = imports
        allImports.append("Chord")
        
        let importLines = allImports.map { return "import \($0)" }
        return importLines.sorted().joined(separator: "\n")
    }

    func generateRequestStructs(_ className: String, _ functions: [Function]) throws -> String
    {
        let structs = try functions.compactMap { try self.generateStruct(className, $0) }
        return structs.joined(separator: "\n\n")
    }

    func generateStruct(_ className: String, _ function: Function) throws -> String?
    {
        if function.parameters.isEmpty
        {
            return nil
        }

        let fields = function.parameters.map { self.generateStructField($0) }
        let fieldList = fields.joined(separator: "\n")

        let parameters = function.parameters.map { self.generateParameter($0) }
        let parameterList = parameters.joined(separator: ", ")

        let inits = function.parameters.map { self.generateInit($0) }
        let initList = inits.joined(separator: "\n")

        return """
        public struct \(className)\(function.name.capitalized): Codable
        {
        \(fieldList)

            public init(\(parameterList))
            {
        \(initList)
            }
        }
        """
    }

    func generateStructField(_ parameter: FunctionParameter) -> String
    {
        return "    public let \(parameter.name): \(parameter.type)"
    }

    func generateParameter(_ parameter: FunctionParameter) -> String
    {
        return "\(parameter.name): \(parameter.type)"
    }

    func generateInit(_ parameter: FunctionParameter) -> String
    {
        return "        self.\(parameter.name) = \(parameter.name)"
    }

    func generateArgument(_ argument: FunctionParameter) -> String
    {
        return "\(argument.name): \(argument.name)"
    }
}

public enum ClockworkError: Error
{
    case sourcesDirectoryDoesNotExist
    case noMatches
    case tooManyMatches
    case badFunctionFormat
    case noOutputDirectory
    case templateNotFound
}
