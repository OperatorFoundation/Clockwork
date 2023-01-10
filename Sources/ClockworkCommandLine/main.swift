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

    mutating public func run() throws
    {
        print("Clockwork \(source) \(output)")
        let clockwork = Clockwork()
        try clockwork.generate(source: source, output: output)
    }
}

CommandLine.main()
