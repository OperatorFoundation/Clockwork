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
        if kotlin
        {
            print("ClockworkKotlin \(source) \(output)")
            let clockwork = ClockworkKotlin()
            try clockwork.generate(source: source, output: output)
        }
        else if python
        {
            print("ClockworkPython \(source) \(output)")
            let clockwork = ClockworkPython()
            try clockwork.generate(source: source, output: output)
        }
        else
        {
            print("Clockwork \(source) \(output)")
            let clockwork = Clockwork()
            try clockwork.generate(source: source, output: output)
        }
    }
}

CommandLine.main()
