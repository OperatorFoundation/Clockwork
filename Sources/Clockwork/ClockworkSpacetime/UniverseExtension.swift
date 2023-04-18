//
//  UniverseExtension.swift
//  
//
//  Created by Dr. Brandon Wiley on 1/8/23.
//

import Foundation

extension ClockworkSpacetime
{
    public func generateUniverseExtensionFile(_ input: URL, _ output: URL)
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

            let outputFile = output.appending(component: "Universe+\(className).swift")
            try self.generateUniverseExtension(outputFile, className, functions)
        }
        catch
        {
            print(error)
        }
    }

    func generateUniverseExtension(_ outputURL: URL, _ className: String, _ functions: [Function]) throws
    {
        print("Generating \(className)Client...")

        let outputFile = outputURL.appending(component: "Universe+\(className).swift")
        let result = try self.generateUniverseExtensionSource(className, functions)
        try result.write(to: outputFile, atomically: true, encoding: .utf8)
    }

    func generateUniverseExtensionSource(_ className: String, _ functions: [Function]) throws -> String
    {
        let date = Date() // now
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none

        let dateString = formatter.string(from: date)

        let functions = try self.generateFunctions(className, functions)

        return """
        //
        //  Universe+\(className).swift
        //
        //
        //  Created by Clockwork on \(dateString).
        //

        import Foundation

        import Spacetime
        import Universe

        extension Universe
        {
        \(functions)
        }

        public enum \(className)Error: Error
        {
            case failure
        }
        """
    }

    func generateFunctions(_ className: String, _ functions: [Function]) throws -> String
    {
        let results = try functions.compactMap { try self.generateFunction(className, $0, includeDefault: functions.count > 1) }
        return results.joined(separator: "\n\n")
    }

    func generateFunction(_ className: String, _ function: Function, includeDefault: Bool) throws -> String
    {
        let signature = self.generateFunctionSignature(function)
        let body = self.generateFunctionBody(className, function, includeDefault: includeDefault)

        return """
        \(signature)
        \(body)
        """
    }

    func generateFunctionSignature( _ function: Function) -> String
    {
        let parameters = function.parameters.map { self.generateParameter($0) }
        let parameterList = parameters.joined(separator: ", ")

        if let returnType = function.returnType
        {
            return "    public func \(function.name)(\(parameterList)) throws -> \(returnType)"
        }
        else
        {
            return "    public func \(function.name)(\(parameterList)) throws"
        }
    }

    func generateFunctionBody(_ className: String, _ function: Function, includeDefault: Bool) -> String
    {
        let argumentSource: String
        if function.parameters.isEmpty
        {
            argumentSource = ""
        }
        else
        {
            let arguments = function.parameters.map { self.generateArgument($0) }
            argumentSource = arguments.joined(separator: ", ")
        }

        let returnHandler: String
        if function.returnType == nil
        {
            returnHandler = """
                        case is \(className)\(function.name.capitalizingFirstLetter())Response:
                            return
            """
        }
        else
        {
            returnHandler = """
                        case let response as \(className)\(function.name.capitalizingFirstLetter())Response:
                            return response.result
            """
        }

        return """
            {
                let request = \(className)\(function.name.capitalizingFirstLetter())Request(\(argumentSource))
                let result = self.processEffect(request)

                switch result
                {
        \(returnHandler)

                    default:
                        throw \(className)Error.failure
                }
            }
        """

    }

    func generateArgument(_ argument: FunctionParameter) -> String
    {
        return "\(argument.name): \(argument.name)"
    }

}
