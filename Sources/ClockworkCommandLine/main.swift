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
    static let configuration = CommandConfiguration(
        commandName: "clockwork",
        subcommands: [New.self, Run.self]
    )
}

extension CommandLine
{
    struct New: ParsableCommand
    {
        @Argument(help: "path to .json config file")
        var config: String

        @Argument(help: "path to logic model file (.swift or .py)")
        var source: String

        @Option(help: "directory to output generated Messages.swift file")
        var swiftMessages: String?

        @Option(help: "directory to output generated Server.swift file")
        var swiftServer: String?

        @Option(help: "directory to output generated Client.swift file")
        var swiftClient: String?

        @Option(help: "package name for generated Kotlin files")
        var kotlinPackage: String?

        @Option(help: "directory to output generated Messages.kt file")
        var kotlinMessages: String?

        @Option(help: "directory to output generated Client.kt file")
        var kotlinClient: String?

        @Option(help: "directory to output generated Messages.py file")
        var pythonMessages: String?

        @Option(help: "directory to output generated Server.py file")
        var pythonServer: String?

        @Option(help: "directory to output generated Client.py file")
        var pythonClient: String?

        mutating public func run() throws
        {
            let configURL = URL(fileURLWithPath: config)

            if (kotlinMessages != nil) || (kotlinClient != nil)
            {
                guard kotlinPackage != nil else
                {
                    throw ClockworkCommandLineError.packageRequired
                }
            }

            let clockworkConfig = ClockworkConfig(source: source, swiftMessages: swiftMessages, kotlinMessages: kotlinMessages, pythonMessages: pythonMessages, swiftClient: swiftClient, pythonClient: pythonClient, kotlinClient: kotlinClient, swiftServer: swiftServer, pythonServer: pythonServer, kotlinPackage: kotlinPackage)
            try clockworkConfig.save(url: configURL)
        }
    }
}

extension CommandLine
{
    struct Run: ParsableCommand
    {
        @Argument(help: "path to .json config file")
        var configPath: String

        mutating public func run() throws
        {
            let url = URL(fileURLWithPath: configPath)
            let config = try ClockworkConfig.load(url: url)

            let parser: any Parser

            let sourceURL = URL(fileURLWithPath: config.source)
            switch sourceURL.pathExtension
            {
                case "swift":
                    parser = SwiftParser()

                case "py":
                    parser = PythonParser()

                default:
                    throw ClockworkCommandLineError.noParser(sourceURL.pathExtension)
            }

            let clockworkKotlin = KotlinGenerator(parser: parser)

            if (config.kotlinMessages != nil) || (config.kotlinClient != nil)
            {
                guard config.kotlinPackage != nil else
                {
                    throw ClockworkCommandLineError.packageRequired
                }
            }

            if let kotlinMessages = config.kotlinMessages
            {
                let outputURL = URL(fileURLWithPath: kotlinMessages)
                clockworkKotlin.generateMessages(sourceURL, outputURL, config.kotlinPackage)
            }

            if let kotlinClient = config.kotlinClient
            {
                let outputURL = URL(fileURLWithPath: kotlinClient)
                clockworkKotlin.generateClient(sourceURL, outputURL, config.kotlinPackage)
            }

            let clockworkPython = PythonGenerator(parser: parser)
            if let pythonMessages = config.pythonMessages
            {
                let outputURL = URL(fileURLWithPath: pythonMessages)
                clockworkPython.generateMessages(sourceURL, outputURL)
            }

            if let pythonServer = config.pythonServer
            {
                let outputURL = URL(fileURLWithPath: pythonServer)
                clockworkPython.generateServer(sourceURL, outputURL)
            }

            let clockworkSwift = SwiftGenerator(parser: parser)
            if let swiftMessages = config.swiftMessages
            {
                let outputURL = URL(fileURLWithPath: swiftMessages)
                clockworkSwift.generateMessages(sourceURL, outputURL)
            }

            if let swiftClient = config.swiftClient
            {
                let outputURL = URL(fileURLWithPath: swiftClient)
                clockworkSwift.generateClient(sourceURL, outputURL)
            }

            if let swiftServer = config.swiftServer
            {
                let outputURL = URL(fileURLWithPath: swiftServer)
                clockworkSwift.generateServer(sourceURL, outputURL)
            }
        }
    }
}

public enum ClockworkCommandLineError: Error
{
    case noParser(String)
    case packageRequired
}

CommandLine.main()
