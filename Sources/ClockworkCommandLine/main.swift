//
//  main.swift
//  
//
//  Created by Dr. Brandon Wiley on 1/1/23.
//

import ArgumentParser
import Foundation

import Gardener

import Clockwork

struct CommandLine: ParsableCommand
{
    static let configuration = CommandConfiguration(commandName: "clockwork")

    @Argument(help: "path to .swift source files for business logic")
    var source: String

    @Argument(help: "directory to output generated files")
    var output: String

    @Flag(help: "output Kotlin files instead of Swift")
    var kotlin: Bool = false

    @Flag(help: "output python files instead of Swift")
    var python: Bool = false

    mutating public func run() throws
    {
        let parser: any Parser
        let sourceURL = URL(fileURLWithPath: source)
        switch sourceURL.pathExtension
        {
            case "swift":
                parser = SwiftParser()

            case "py":
                parser = PythonParser()

            default:
                throw ClockworkCommandLineError.noParser(sourceURL.pathExtension)
        }

        if kotlin
        {
            print("ClockworkKotlin \(source) \(output)")
            let clockwork = ClockworkKotlin(parser: parser)
            try clockwork.generate(source: source, output: output)
        }
        else if python
        {
            print("ClockworkPython \(source) \(output)")
            let clockwork = ClockworkPython(parser: parser)
            try clockwork.generate(source: source, output: output)
        }
        else
        {
            print("Clockwork \(source) \(output)")
            let clockwork = SwiftGenerator(parser: parser)
            try clockwork.generate(source: source, output: output)
        }
    }
}

public enum ClockworkCommandLineError: Error
{
    case noParser(String)
}

CommandLine.main()
