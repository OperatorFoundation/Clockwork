//
//  main.swift
//
//
//  Created by Dr. Brandon Wiley on 1/8/23.
//

import ArgumentParser
import Foundation

import Gardener

import Clockwork

struct CommandLine: ParsableCommand
{
    static let configuration = CommandConfiguration(commandName: "clockwork")

    @Argument(help: "directory in which to find the .swift source files")
    var sources: String

    @Argument(help: "directory to output generated files")
    var output: String

    mutating public func run() throws
    {
        print("Clockwork \(sources) \(output)")
        let clockwork = ClockworkSpacetime()
        try clockwork.generate(sources: sources, output: output)
    }
}

CommandLine.main()
