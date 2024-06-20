//
//  SwiftGeneratorMessages.swift
//  
//
//  Created by Dr. Brandon Wiley on 7/17/23.
//

import Foundation

extension SwiftGenerator
{
    public func generateMessages(_ input: URL, _ output: URL)
    {
        do
        {
            let source = try String(contentsOf: input)
            let className = try self.parser.findClassName(input, source)
            let imports = try self.parser.findImports(source)
            let functions = try self.parser.findFunctions(source)

            guard functions.count > 0 else
            {
                return
            }

            try self.generateMessages(output, imports, className, functions)
        }
        catch
        {
            print(error)
        }
    }

    func generateMessages(_ outputURL: URL, _ imports: [String], _ className: String, _ functions: [Function]) throws
    {
        print("Generating \(className)Messages.swift...")

        let outputFile = outputURL.appending(component: "\(className)Messages.swift")
        let result = try self.generateRequestText(imports, className, functions)
        try result.write(to: outputFile, atomically: true, encoding: .utf8)
    }

    func generateRequestText(_ imports: [String], _ className: String, _ functions: [Function]) throws -> String
    {
        let date = Date() // now
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none

        let dateString = formatter.string(from: date)

        let requestEnums = self.generateRequestEnumsText(className, functions)
        let requestStructs = try self.generateRequestStructs(className, functions)

        let responseEnums = try self.generateResponseEnumsText(functions)
        let importLines = self.generateImports(imports)

        return """
        //
        //  \(className)Messages.swift
        //
        //
        //  Created by Clockwork on \(dateString).
        //

        \(importLines)

        public struct \(className)Error: Error, Codable
        {
            let message: String

            public var localizedDescription: String
            {
                return "\(className)Error: " + self.message
            }

            public init(_ message: String)
            {
                self.message = message
            }
        }

        public enum \(className)Request: Codable
        {
        \(requestEnums)
        }

        \(requestStructs)

        public enum \(className)Response: Codable
        {
        \(responseEnums)
        }
        """
    }

    func generateRequestEnumsText(_ className: String, _ functions: [Function]) -> String
    {
        let enums = functions.map { self.generateRequestEnumCase(className, $0) }
        return enums.joined(separator: "\n")
    }

    func generateRequestEnumCase(_ className: String, _ function: Function) -> String
    {
        if function.parameters.isEmpty
        {
            return "    case \(function.name.capitalized)Request"
        }
        else
        {
            return "    case \(function.name.capitalized)Request(value: \(className)\(function.name.capitalized))"
        }
    }

    func generateResponseEnumsText(_ functions: [Function]) throws -> String
    {
        let enums = try functions.map { try self.generateResponseEnumCase($0) }
        return enums.joined(separator: "\n")
    }

    func generateResponseEnumCase(_ function: Function) throws -> String
    {
        if let returnType = function.returnType
        {
            return "case \(function.name.capitalized)Response(value: \(returnType))"
        }
        else
        {
            return "case \(function.name.capitalized)Response"
        }
    }
}
