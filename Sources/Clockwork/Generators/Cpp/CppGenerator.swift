//
//  CppGenerator.swift
//
//
//  Created by Dr. Brandon Wiley on 4/13/23.
//

import ArgumentParser
import Foundation

import Gardener

public class CppGenerator
{
    let parser: any Parser

    public init(parser: any Parser)
    {
        self.parser = parser
    }

    func makeRequestCaseName(_ className: String, _ function: Function) -> String
    {
        return "\(className)\(function.name.capitalized)Request"
    }

    func makeResponseCaseName(_ className: String, _ function: Function) -> String
    {
        return "\(className)\(function.name.capitalized)Response"
    }

    func makeRequestName(_ className: String) -> String
    {
        return "\(className)Request"
    }

    func makeResponseName(_ className: String) -> String
    {
        return "\(className)Response"
    }

    func makeMethodName(_ className: String, _ function: Function) -> String
    {
        return "\(function.name)"
    }

    func makeHandlerName(_ className: String) -> String
    {
        return "\(className)Handler"
    }

    func makeModuleName(_ className: String) -> String
    {
        return "\(className)Module"
    }

    func makeUniverseName(_ className: String) -> String
    {
        return "\(className)Universe"
    }

    func generateServerArgument(_ parameter: FunctionParameter) -> String
    {
        return "\(parameter.name)"
    }

    func generateRequestParameters(_ function: Function) -> String
    {
        let enums = function.parameters.map { self.generateRequestParameter($0) }
        return enums.joined(separator: ", ")
    }

    func generateRequestParameter(_ parameter: FunctionParameter) -> String
    {
        return "    \(parameter.type) \(parameter.name);"
    }

    func generateArgument(_ argument: FunctionParameter) -> String
    {
        return "\(argument.name)"
    }

    func generatePythonMessages(_ outputURL: URL, _ className: String, _ functions: [Function]) throws
    {
        print("Generating \(className)Messages.py...")

        let outputFile = outputURL.appending(component: "\(className)Messages.py")
        let result = try self.generateMessagesText(className, functions)
        try result.write(to: outputFile, atomically: true, encoding: .utf8)
    }
}

public enum CppGeneratorError: Error
{
    case emptyParameters
    case sourcesDirectoryDoesNotExist
    case noMatches
    case tooManyMatches
    case badFunctionFormat
    case noOutputDirectory
    case templateNotFound
}
