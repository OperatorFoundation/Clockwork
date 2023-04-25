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

    func makeModuleName(_ className: String) -> String
    {
        return "\(className)Module"
    }

    func makeUniverseName(_ className: String) -> String
    {
        return "\(className)Universe"
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
