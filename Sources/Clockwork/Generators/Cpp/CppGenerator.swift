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
        return "\(parameter.name)"
    }

    func generateParameter(_ parameter: FunctionParameter) -> String
    {
        return "\(parameter.name)"
    }

    func generateFunctions(_ className: String, _ functions: [Function]) throws -> String
    {
        let results = try functions.compactMap { try self.generateFunction(className, $0, includeDefault: functions.count > 1) }
        return results.joined(separator: "\n\n")
    }

    func generateFunction(_ className: String, _ function: Function, includeDefault: Bool) throws -> String
    {
        let signature = self.generateFunctionSignature(function)
        let body = self.generateFunctionBody(className, function, includeDefault: includeDefault)

        return """
        \(signature)
        \(body)
        """
    }

    func generateFunctionSignature( _ function: Function) -> String
    {
        if function.parameters.isEmpty
        {
            return "    def \(function.name)(self):"
        }
        else
        {
            let parameters = function.parameters.map { self.generateParameter($0) }
            let parameterList = parameters.joined(separator: ", ")

            return "    def \(function.name)(self, \(parameterList)):"
        }
    }

    func generateFunctionBody(_ className: String, _ function: Function, includeDefault: Bool) -> String
    {
        let structHandler: String
        if function.parameters.isEmpty
        {
            structHandler = "()"
        }
        else
        {
            let arguments = function.parameters.map { self.generateArgument($0) }
            let argumentList = arguments.joined(separator: ", ")
            structHandler = "(\(argumentList))"
        }

        let returnHandler: String
        if function.returnType == nil
        {
            returnHandler = """
                    if isinstance(response, \(function.name.capitalized)Response):
                        return
            """
        }
        else
        {
            returnHandler = """
                    if isistance(response, \(function.name.capitalized)Response):
                        return response.value
            """
        }

        let defaultHandler: String
        if includeDefault
        {
            defaultHandler = """
                    else:
                        raise Exception("bad return type")
            """
        }
        else
        {
            defaultHandler = ""
        }

        return """
                message = \(function.name.capitalized)Request\(structHandler)
                if not self.connection.write(message):
                    raise Exception("write failed")

                response = self.connection.read()
                if not response:
                    raise Exception("read failed")

        \(returnHandler)
        \(defaultHandler)
        """

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
