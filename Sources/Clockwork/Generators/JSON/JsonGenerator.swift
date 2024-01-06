//
//  JsonGenerator.swift
//
//
//  Created by Dr. Brandon Wiley on 12/30/23.
//

import ArgumentParser
import Foundation

import Gardener

public class JsonGenerator
{
    let parser: any Parser

    public init(parser: any Parser)
    {
        self.parser = parser
    }

    public func generate(_ input: URL, _ output: URL)
    {
        do
        {
            let source = try String(contentsOf: input)
            let className = try self.parser.findClassName(input, source)

            let functions = try self.parser.findFunctions(source)

            guard functions.count > 0 else
            {
                return
            }

            let saveURL = output.appendingPathComponent("\(className).json")

            let extracted = ExtractedInterface(className: className, functions: functions)
            try extracted.save(saveURL)
        }
        catch
        {
            print(error)
        }
    }
}

public enum JsonGeneratorError: Error
{
    case sourcesDirectoryDoesNotExist
    case noMatches
    case tooManyMatches
    case badFunctionFormat
    case noOutputDirectory
    case templateNotFound
}
