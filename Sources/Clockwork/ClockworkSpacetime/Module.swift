//
//  Module.swift
//  
//
//  Created by Dr. Brandon Wiley on 1/8/23.
//

import Foundation

extension ClockworkSpacetime
{
    public func generateModuleFile(_ input: URL, _ output: URL)
    {
        do
        {
            let source = try String(contentsOf: input)
            let className = try self.findClassName(source)

            let functions = try self.findFunctions(source)

            guard functions.count > 0 else
            {
                return
            }

            let outputFile = output.appending(component: "\(className)Module.swift")
            try self.generateModule(outputFile, className, functions)
        }
        catch
        {
            print(error)
        }
    }

    func generateModule(_ outputURL: URL, _ className: String, _ functions: [Function]) throws
    {
        print("Generating \(outputURL.path)...")

        let outputFile = outputURL.appending(component: "\(className)Module.swift")
        let result = try self.generateModuleSource(className, functions)
        try result.write(to: outputFile, atomically: true, encoding: .utf8)
    }

    func generateModuleSource(_ className: String, _ functions: [Function]) throws -> String
    {
        let date = Date() // now
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none

        let dateString = formatter.string(from: date)

        let cases = self.generateModuleCases(className, functions)

        return """
        //
        //  \(className)Module.swift
        //
        //
        //  Created by Clockwork on \(dateString).
        //

        import Foundation
        #if os(macOS) || os(iOS)
        import os.log
        #else
        import Logging
        #endif

        import Chord
        import Simulation
        import Spacetime

        public class \(className)Module: Module
        {
            static public let name = "\(className)"

            public var logger: Logger?

            let handler: \(className)

            public init(handler: \(className))
            {
                self.handler = handler
            }

            public func name() -> String
            {
                return Self.name
            }

            public func setLogger(logger: Logger?)
            {
                self.logger = logger
            }

            public func handleEffect(_ effect: Effect, _ channel: BlockingQueue<Event>) -> Event?
            {
                switch effect
                {
        \(cases)

                    default:
                        let response = Failure(effect.id)
                        print(response.description)
                        return response
                }
            }

            public func handleExternalEvent(_ event: Event)
            {
                return
            }
        }
        """
    }

    func generateModuleCases(_ className: String, _ functions: [Function]) -> String
    {
        let cases = functions.map { self.generateModuleCase(className, $0) }
        return cases.joined(separator: "\n")
    }

    func generateModuleCase(_ className: String, _ function: Function) -> String
    {
        if function.parameters.isEmpty
        {
            if function.returnType == nil
            {
                return """
                            case let request as \(className)\(function.name.capitalized)Request:
                                self.handler.\(function.name)()
                                let response = \(className)\(function.name.capitalized)Response(request.id)
                                print(response.description)
                                return response
                """
            }
            else
            {
                return """
                            case let request as \(className)\(function.name.capitalized)Request:
                                let result = self.handler.\(function.name)()
                                let response = \(className)\(function.name.capitalized)Response(request.id, result)
                                print(response.description)
                                return response
                """
            }
        }
        else
        {
            let arguments = function.parameters.map { self.generateModuleEffectArgument($0) }
            let argumentList = arguments.joined(separator: ", ")

            if function.returnType == nil
            {
                return """
                            case let request as \(className)\(function.name.capitalized)Request:
                                self.handler.\(function.name)(\(argumentList))
                                let response = \(className)\(function.name.capitalized)Response(request.id)
                                print(response.description)
                                return response
                """
            }
            else
            {
                return """
                            case let request as \(className)\(function.name.capitalized)Request:
                                let result = self.handler.\(function.name)(\(argumentList))
                                let response = \(className)\(function.name.capitalized)Response(request.id, result)
                                print(response.description)
                                return response
                """
            }
        }
    }

    func generateModuleEffectArgument(_ parameter: FunctionParameter) -> String
    {
        return "\(parameter.name): request.\(parameter.name)"
    }
}
