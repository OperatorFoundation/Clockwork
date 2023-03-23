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

    public func generateMessages(_ input: URL, _ output: URL)
    {
        do
        {
            let source = try String(contentsOf: input)
            let className = try self.parser.findClassName(source)
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

    public func generateClient(_ input: URL, _ output: URL)
    {
        do
        {
            let source = try String(contentsOf: input)
            let className = try self.parser.findClassName(source)
            let imports = try self.parser.findImports(source)
            let functions = try self.parser.findFunctions(source)

            guard functions.count > 0 else
            {
                return
            }

            try self.generateClient(output, imports, className, functions)
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
            let imports = try self.parser.findImports(source)
            let functions = try self.parser.findFunctions(source)

            guard functions.count > 0 else
            {
                return
            }

            try self.generateServer(output, imports, className, functions)
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

    func generateClient(_ outputURL: URL, _ imports: [String], _ className: String, _ functions: [Function]) throws
    {
        print("Generating \(className)Client.swift...")

        let outputFile = outputURL.appending(component: "\(className)Client.swift")
        let result = try self.generateClientText(imports, className, functions)
        try result.write(to: outputFile, atomically: true, encoding: .utf8)
    }

    func generateServer(_ outputURL: URL, _ imports: [String], _ className: String, _ functions: [Function]) throws
    {
        print("Generating \(className)Server.swift...")

        let outputFile = outputURL.appending(component: "\(className)Server.swift")
        let result = try self.generateServerText(imports, className, functions)
        try result.write(to: outputFile, atomically: true, encoding: .utf8)
    }

    func generateRequestText(_ imports: [String], _ className: String, _ functions: [Function]) throws -> String
    {
        let date = Date() // now
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none

        let dateString = formatter.string(from: date)

        let requestEnums = self.generateRequestEnumsText(functions)
        let requestStructs = try self.generateRequestStructs(functions)

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

    func generateClientText(_ imports: [String], _ className: String, _ functions: [Function]) throws -> String
    {
        let date = Date() // now
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none

        let dateString = formatter.string(from: date)

        let functions = try self.generateFunctions(className, functions)
        let importLines = self.generateImports(imports)

        return """
        //
        //  \(className)Client.swift
        //
        //
        //  Created by Clockwork on \(dateString).
        //

        import Foundation

        import TransmissionTypes

        import \(className)
        \(importLines)

        public class \(className)Client
        {
            let connection: TransmissionTypes.Connection
            let lock = DispatchSemaphore(value: 1)

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

    func generateServerText(_ imports: [String], _ className: String, _ functions: [Function]) throws -> String
    {
        let date = Date() // now
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none

        let dateString = formatter.string(from: date)

        let cases = self.generateServerCases(className, functions)
        let importLines = self.generateImports(imports)

        return """
        //
        //  \(className)Server.swift
        //
        //
        //  Created by Clockwork on \(dateString).
        //

        import Foundation

        import TransmissionTypes

        import \(className)
        \(importLines)

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
        
                        print("Received a request:\\n\\(requestData.string)")

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

                        do
                        {
                            let response = \(className)Error(error.localizedDescription)
                            let encoder = JSONEncoder()
                            let responseData = try encoder.encode(response)
                            print("Sending a response:\\n\\(responseData.string)")
                            let _ = connection.writeWithLengthPrefix(data: responseData, prefixSizeInBits: 64)
                        }
                        catch
                        {
                            print(error)
                        }

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

    func generateImports(_ imports: [String]) -> String
    {
        let importLines = imports.map { return "import \($0)" }
        return importLines.joined(separator: "\n")
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
                                        let response = try \(className)Response.\(function.name.capitalized)Response
                                        let encoder = JSONEncoder()
                                        let responseData = try encoder.encode(response)
                                        print("Sending a response:\\n\\(responseData.string)")
                
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
                                        let response = \(className)Response.\(function.name.capitalized)Response
                                        let encoder = JSONEncoder()
                                        let responseData = try encoder.encode(response)
                                        print("Sending a response:\\n\\(responseData.string)")
                
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
                                        let response = \(className)Response.\(function.name.capitalized)Response(value: result)
                                        let encoder = JSONEncoder()
                                        let responseData = try encoder.encode(response)
                                        print("Sending a response:\\n\\(responseData.string)")
                
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
                                        let response = \(className)Response.\(function.name.capitalized)Reponse(value: result)
                                        let encoder = JSONEncoder()
                                        let responseData = try encoder.encode(response)
                                        print("Sending a response:\\n\\(responseData.string)")
                
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
                                    case .\(function.name.capitalized)Request(let value):
                                        try self.handler.\(function.name)(\(argumentList))
                                        let response = \(className)Response.\(function.name.capitalized)Response
                                        let encoder = JSONEncoder()
                                        let responseData = try encoder.encode(response)
                                        print("Sending a response:\\n\\(responseData.string)")
                
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
                                        self.handler.\(function.name)(\(argumentList))
                                        let response = \(className)Response.\(function.name.capitalized)Response
                                        let encoder = JSONEncoder()
                                        let responseData = try encoder.encode(response)
                                        print("Sending a response:\\n\\(responseData.string)")
                
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
                                        let response = try \(className)Response.\(function.name.capitalized)Response(value: result)
                                        let encoder = JSONEncoder()
                                        let responseData = try encoder.encode(response)
                                        print("Sending a response:\\n\\(responseData.string)")
                
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
                                        let response = \(className)Response.\(function.name.capitalized)Response(value: result)
                                        let encoder = JSONEncoder()
                                        let responseData = try encoder.encode(response)
                                        print("Sending a response:\\n\\(responseData.string)")
                
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
            return "    case \(function.name.capitalized)Request(value: \(function.name.capitalized))"
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
            structHandler = "(value: \(function.name.capitalized)(\(argumentList)))"
        }

        let returnHandler: String
        if function.returnType == nil
        {
            returnHandler = """
                            case .\(function.name.capitalized)Response:
                                return
            """
        }
        else
        {
            returnHandler = """
                            case .\(function.name.capitalized)Response(let value):
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
                defer
                {
                    self.lock.signal()
                }
                self.lock.wait()

                let message = \(className)Request.\(function.name.capitalized)Request\(structHandler)
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

                do
                {
                    let response = try decoder.decode(\(className)Response.self, from: responseData)
                    switch response
                    {
            \(returnHandler)
            \(defaultHandler)
                    }
                }
                catch
                {
                    let remoteError = try decoder.decode(\(className)Error.self, from: responseData)
                    throw remoteError
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
