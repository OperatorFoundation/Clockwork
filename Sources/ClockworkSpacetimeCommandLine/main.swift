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

    @Argument(help: "path to the module logic .swift source files")
    var source: String

    @Argument(help: "directory to output interactions")
    var interactionsOutput: String

    @Argument(help: "directory to output Module")
    var moduleOutput: String

    @Argument(help: "directory to output Universe extension")
    var universeOutput: String

    mutating public func run() throws
    {
        print("Clockwork \(source) \(interactionsOutput) \(moduleOutput) \(universeOutput)")
        let clockwork = ClockworkSpacetime()
        try clockwork.generate(source: source, interactionsOutput: interactionsOutput, moduleOutput: moduleOutput, universeOutput: universeOutput)
    }
}

CommandLine.main()
