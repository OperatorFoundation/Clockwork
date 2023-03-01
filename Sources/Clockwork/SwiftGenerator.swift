//
//  Clockwork.swift
//  
//
//  Created by Dr. Brandon Wiley on 1/5/23.
//

import ArgumentParser
import Foundation

import Gardener

public class SwiftGenerator
{
    let parser: any Parser

    public init(parser: any Parser)
    {
        self.parser = parser
    }

    public func generate(source: String, output: String) throws
    {
        let outputURL = URL(fileURLWithPath: output)
        if !File.exists(output)
        {
            guard File.makeDirectory(url: outputURL) else
            {
                throw ClockworkError.noOutputDirectory
            }
        }

        let sourceURL = URL(fileURLWithPath: source)
        self.generate(sourceURL, outputURL)
    }

    public func generate(_ input: URL, _ outputURL: URL)
    {
        do
        {
            let source = try String(contentsOf: input)
//            let imports = try self.parser.findImports(source)
            let className = try self.parser.findClassName(source)

            let functions = try self.parser.findFunctions(source)

            guard functions.count > 0 else
            {
                return
            }

            let imports: [String] = []

            try self.generateMessages(outputURL, imports, className, functions)
            try self.generateClient(outputURL, imports, className, functions)
            try self.generateServer(outputURL, imports, className, functions)
        }
        catch
        {
            print(error)
        }
    }

    public func generateMessages(_ input: URL, _ output: URL)
    {
        do
        {
            let source = try String(contentsOf: input)
            let className = try self.parser.findClassName(source)

            let functions = try self.parser.findFunctions(source)

            guard functions.count > 0 else
            {
                return
            }

            let outputFile = output.appending(component: "\(className)Messages.swift")
            try self.generateMessages(outputFile, [], className, functions)
        }
        catch
        {
            print(error)
        }
    }

    public func generateClient(_ input: URL, _ output: URL)
    {
        do
        {
            let source = try String(contentsOf: input)
            let className = try self.parser.findClassName(source)

            let functions = try self.parser.findFunctions(source)

            guard functions.count > 0 else
            {
                return
            }

            let outputFile = output.appending(component: "\(className)Client.swift")
            try self.generateClient(outputFile, [], className, functions)
        }
        catch
        {
            print(error)
        }
    }

    public func generateServer(_ input: URL, _ output: URL)
    {
        do
        {
            let source = try String(contentsOf: input)
            let className = try self.parser.findClassName(source)

            let functions = try self.parser.findFunctions(source)

            guard functions.count > 0 else
            {
                return
            }

            let outputFile = output.appending(component: "\(className)Server.swift")
            try self.generateServer(outputFile, [], className, functions)
        }
        catch
        {
            print(error)
        }
    }

    func generateMessages(_ outputURL: URL, _ imports: [String], _ className: String, _ functions: [Function]) throws
    {
        print("Generating \(className)Messages...")

        let outputFile = outputURL.appending(component: "\(className)Messages.swift")
        let result = try self.generateRequestText(className, functions)
        try result.write(to: outputFile, atomically: true, encoding: .utf8)
    }

    func generateClient(_ outputURL: URL, _ imports: [String], _ className: String, _ functions: [Function]) throws
    {
        print("Generating \(className)Client...")

        let outputFile = outputURL.appending(component: "\(className)Client.swift")
        let result = try self.generateClientText(className, functions)
        try result.write(to: outputFile, atomically: true, encoding: .utf8)
    }

    func generateServer(_ outputURL: URL, _ imports: [String], _ className: String, _ functions: [Function]) throws
    {
        print("Generating \(className)Server...")

        let outputFile = outputURL.appending(component: "\(className)Server.swift")
        let result = try self.generateServerText(className, functions)
        try result.write(to: outputFile, atomically: true, encoding: .utf8)
    }

    func generateRequestText(_ className: String, _ functions: [Function]) throws -> String
    {
        let date = Date() // now
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none

        let dateString = formatter.string(from: date)

        let requestEnums = self.generateRequestEnumsText(functions)
        let requestStructs = try self.generateRequestStructs(functions)

        let responseEnums = try self.generateResponseEnumsText(functions)

        return """
        //
        //  \(className)Messages.swift
        //
        //
        //  Created by Clockwork on \(dateString).
        //

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

    func generateClientText(_ className: String, _ functions: [Function]) throws -> String
    {
        let date = Date() // now
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none

        let dateString = formatter.string(from: date)

        let functions = try self.generateFunctions(className, functions)

        return """
        //
        //  \(className)Client.swift
        //
        //
        //  Created by Clockwork on \(dateString).
        //

        import Foundation

        import TransmissionTypes

        public class \(className)Client
        {
            let connection: TransmissionTypes.Connection

            public init(connection: TransmissionTypes.Connection)
            {
                self.connection = connection
            }

        \(functions)
        }

        public enum \(className)ClientError: Error
        {
            case connectionRefused(String, Int)
            case writeFailed
            case readFailed
            case badReturnType
        }
        """
    }

    func generateServerText(_ className: String, _ functions: [Function]) throws -> String
    {
        let date = Date() // now
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none

        let dateString = formatter.string(from: date)

        let cases = self.generateServerCases(className, functions)

        return """
        //
        //  \(className)Server.swift
        //
        //
        //  Created by Clockwork on \(dateString).
        //

        import Foundation

        import TransmissionTypes

        public class \(className)Server
        {
            let listener: TransmissionTypes.Listener
            let handler: \(className)

            var running: Bool = true

            public init(listener: TransmissionTypes.Listener, handler: \(className))
            {
                self.listener = listener
                self.handler = handler

                Task
                {
                    self.acceptLoop()
                }
            }

            public func shutdown()
            {
                self.running = false
            }

            func acceptLoop()
            {
                while self.running
                {
                    do
                    {
                        let connection = try self.listener.accept()

                        Task
                        {
                            self.handleConnection(connection)
                        }
                    }
                    catch
                    {
                        print(error)
                        self.running = false
                        return
                    }
                }
            }

            func handleConnection(_ connection: TransmissionTypes.Connection)
            {
                while self.running
                {
                    do
                    {
                        guard let requestData = connection.readWithLengthPrefix(prefixSizeInBits: 64) else
                        {
                            throw \(className)ServerError.readFailed
                        }

                        let decoder = JSONDecoder()
                        let request = try decoder.decode(\(className)Request.self, from: requestData)
                        switch request
                        {
        \(cases)
                        }
                    }
                    catch
                    {
                        print(error)
                        return
                    }
                }
            }
        }

        public enum \(className)ServerError: Error
        {
            case connectionRefused(String, Int)
            case writeFailed
            case readFailed
            case badReturnType
        }
        """
    }

    func generateServerCases(_ className: String, _ functions: [Function]) -> String
    {
        let cases = functions.map { self.generateServerCase(className, $0) }
        return cases.joined(separator: "\n")
    }

    func generateServerCase(_ className: String, _ function: Function) -> String
    {
        if function.parameters.isEmpty
        {
            if function.returnType == nil
            {
                if function.throwing
                {
                    return """
                                    case .\(function.name.capitalized)Request:
                                        try self.handler.\(function.name)()
                                        let response = try \(className)Response.\(function.name)
                                        let encoder = JSONEncoder()
                                        let responseData = try encoder.encode(response)
                                        guard connection.writeWithLengthPrefix(data: responseData, prefixSizeInBits: 64) else
                                        {
                                            throw \(className)ServerError.writeFailed
                                        }
                """
                }
                else
                {
                    return """
                                    case .\(function.name.capitalized)Request:
                                        self.handler.\(function.name)()
                                        let response = \(className)Response.\(function.name)
                                        let encoder = JSONEncoder()
                                        let responseData = try encoder.encode(response)
                                        guard connection.writeWithLengthPrefix(data: responseData, prefixSizeInBits: 64) else
                                        {
                                            throw \(className)ServerError.writeFailed
                                        }
                """
                }
            }
            else
            {
                if function.throwing
                {
                    return """
                                    case .\(function.name.capitalized)Request:
                                        let result = try self.handler.\(function.name)()
                                        let response = \(className)Response.\(function.name)(result)
                                        let encoder = JSONEncoder()
                                        let responseData = try encoder.encode(response)
                                        guard connection.writeWithLengthPrefix(data: responseData, prefixSizeInBits: 64) else
                                        {
                                            throw \(className)ServerError.writeFailed
                                        }
                """
                }
                else
                {
                    return """
                                    case .\(function.name.capitalized)Request:
                                        let result = self.handler.\(function.name)()
                                        let response = \(className)Response.\(function.name)(result)
                                        let encoder = JSONEncoder()
                                        let responseData = try encoder.encode(response)
                                        guard connection.writeWithLengthPrefix(data: responseData, prefixSizeInBits: 64) else
                                        {
                                            throw \(className)ServerError.writeFailed
                                        }
                """
                }
            }
        }
        else
        {
            let arguments = function.parameters.map { self.generateServerArgument($0) }
            let argumentList = arguments.joined(separator: ", ")

            if function.returnType == nil
            {
                if function.throwing
                {
                    return """
                                    case .\(function.name.capitalized)(let value):
                                        try self.handler.\(function.name)(\(argumentList))
                                        let response = \(className)Response.\(function.name)
                                        let encoder = JSONEncoder()
                                        let responseData = try encoder.encode(response)
                                        guard connection.writeWithLengthPrefix(data: responseData, prefixSizeInBits: 64) else
                                        {
                                            throw \(className)ServerError.writeFailed
                                        }
                """
                }
                else
                {
                    return """
                                    case .\(function.name.capitalized)(let value):
                                        self.handler.\(function.name)(\(argumentList))
                                        let response = \(className)Response.\(function.name)
                                        let encoder = JSONEncoder()
                                        let responseData = try encoder.encode(response)
                                        guard connection.writeWithLengthPrefix(data: responseData, prefixSizeInBits: 64) else
                                        {
                                            throw \(className)ServerError.writeFailed
                                        }
                """
                }
            }
            else
            {
                if function.throwing
                {
                    return """
                                    case .\(function.name.capitalized)Request(let value):
                                        let result = try self.handler.\(function.name)(\(argumentList))
                                        let response = try \(className)Response.\(function.name)(result)
                                        let encoder = JSONEncoder()
                                        let responseData = try encoder.encode(response)
                                        guard connection.writeWithLengthPrefix(data: responseData, prefixSizeInBits: 64) else
                                        {
                                            throw \(className)ServerError.writeFailed
                                        }
                """
                }
                else
                {
                    return """
                                    case .\(function.name.capitalized)Request(let value):
                                        let result = self.handler.\(function.name)(\(argumentList))
                                        let response = \(className)Response.\(function.name)(result)
                                        let encoder = JSONEncoder()
                                        let responseData = try encoder.encode(response)
                                        guard connection.writeWithLengthPrefix(data: responseData, prefixSizeInBits: 64) else
                                        {
                                            throw \(className)ServerError.writeFailed
                                        }
                """
                }
            }
        }
    }

    func generateServerArgument(_ parameter: FunctionParameter) -> String
    {
        return "\(parameter.name): value.\(parameter.name)"
    }

    func generateRequestEnumsText(_ functions: [Function]) -> String
    {
        let enums = functions.map { self.generateRequestEnumCase($0) }
        return enums.joined(separator: "\n")
    }

    func generateRequestEnumCase(_ function: Function) -> String
    {
        if function.parameters.isEmpty
        {
            return "    case \(function.name.capitalized)Request"
        }
        else
        {
            return "    case \(function.name.capitalized)Request(\(function.name.capitalized))"
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
            return "    case \(function.name.capitalized)Response(\(returnType))"
        }
        else
        {
            return "    case \(function.name.capitalized)Response"
        }
    }

    func generateRequestStructs(_ functions: [Function]) throws -> String
    {
        let structs = try functions.compactMap { try self.generateStruct($0) }
        return structs.joined(separator: "\n\n")
    }

    func generateStruct(_ function: Function) throws -> String?
    {
        if function.parameters.isEmpty
        {
            return nil
        }

        let fields = function.parameters.map { self.generateStructField($0) }
        let fieldList = fields.joined(separator: "\n")

        let parameters = function.parameters.map { self.generateParameter($0) }
        let parameterList = parameters.joined(separator: ", ")

        let inits = function.parameters.map { self.generateInit($0) }
        let initList = inits.joined(separator: "\n")

        return """
        public struct \(function.name.capitalized): Codable
        {
        \(fieldList)

            public init(\(parameterList))
            {
        \(initList)
            }
        }
        """
    }

    func generateStructField(_ parameter: FunctionParameter) -> String
    {
        return "    public let \(parameter.name): \(parameter.type)"
    }

    func generateParameter(_ parameter: FunctionParameter) -> String
    {
        return "\(parameter.name): \(parameter.type)"
    }

    func generateInit(_ parameter: FunctionParameter) -> String
    {
        return "        self.\(parameter.name) = \(parameter.name)"
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
        let structHandler: String
        if function.parameters.isEmpty
        {
            structHandler = ""
        }
        else
        {
            let arguments = function.parameters.map { self.generateArgument($0) }
            let argumentList = arguments.joined(separator: ", ")
            structHandler = "(\(function.name.capitalized)(\(argumentList)))"
        }

        let returnHandler: String
        if function.returnType == nil
        {
            returnHandler = """
                        case .\(function.name):
                            return
            """
        }
        else
        {
            returnHandler = """
                        case .\(function.name)(let value):
                            return value
            """
        }

        let defaultHandler: String
        if includeDefault
        {
            defaultHandler = """
                        default:
                            throw \(className)ClientError.badReturnType
            """
        }
        else
        {
            defaultHandler = ""
        }

        return """
            {
                let message = \(className)Request.\(function.name)Request\(structHandler)
                let encoder = JSONEncoder()
                let data = try encoder.encode(message)
                guard self.connection.writeWithLengthPrefix(data: data, prefixSizeInBits: 64) else
                {
                    throw \(className)ClientError.writeFailed
                }

                guard let responseData = self.connection.readWithLengthPrefix(prefixSizeInBits: 64) else
                {
                    throw \(className)ClientError.readFailed
                }

                let decoder = JSONDecoder()
                let response = try decoder.decode(\(className)Response.self, from: responseData)
                switch response
                {
        \(returnHandler)
        \(defaultHandler)
                }
            }
        """

    }

    func generateArgument(_ argument: FunctionParameter) -> String
    {
        return "\(argument.name): \(argument.name)"
    }

}

public enum ClockworkError: Error
{
    case sourcesDirectoryDoesNotExist
    case noMatches
    case tooManyMatches
    case badFunctionFormat
    case noOutputDirectory
    case templateNotFound
}
