//
//  SwiftGeneratorServer.swift
//  
//
//  Created by Dr. Brandon Wiley on 7/17/23.
//

import Foundation

extension SwiftGenerator
{
    public func generateServer(_ input: URL, _ output: URL, authenticateClient: Bool = false, format: SerializationFormat = .json)
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

            try self.generateServer(output, imports, className, functions, authenticateClient: authenticateClient, format: format)
        }
        catch
        {
            print(error)
        }
    }

    func generateServer(_ outputURL: URL, _ imports: [String], _ className: String, _ functions: [Function], authenticateClient: Bool, format: SerializationFormat = .json) throws
    {
        print("Generating \(className)Server.swift...")

        let outputFile = outputURL.appending(component: "\(className)Server.swift")
        let result = try self.generateServerText(imports, className, functions, authenticateClient: authenticateClient, format: format)
        try result.write(to: outputFile, atomically: true, encoding: .utf8)
    }

    func generateServerText(_ imports: [String], _ className: String, _ functions: [Function], authenticateClient: Bool, format: SerializationFormat = .json) throws -> String
    {
        let date = Date() // now
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none

        let dateString = formatter.string(from: date)

        let cases = self.generateServerCases(className, functions, authenticateClient: authenticateClient)
        let importLines = self.generateImports(imports)

        let encoder: String
        let decoder: String
        let codableImports: String
        switch format
        {
            case .json:
                encoder = "JSONEncoder"
                decoder = "JSONDecoder"
                codableImports = ""

            case .cbor:
                encoder = "CBOREncoder"
                decoder = "CBORDecoder"
                codableImports = "import PotentCodables"
        }

        if authenticateClient
        {
            return """
            //
            //  \(className)Server.swift
            //
            //
            //  Created by Clockwork on \(dateString).
            //

            import Foundation

            #if os(macOS)
            import os.log
            #else
            import Logging
            #endif

            import TransmissionNametag
            import TransmissionTypes
            \(codableImports)
            \(importLines)

            public class \(className)Server
            {
                let listener: TransmissionTypes.Listener
                let handler: \(className)
                let logger: Logger
                let acceptQueue = DispatchQueue(label: "SwitchboardAcceptQueue")

                var running: Bool = true

                public init(listener: TransmissionTypes.Listener, handler: \(className), logger: Logger) async
                {
                    self.listener = listener
                    self.handler = handler
                    self.logger = logger

                    await AsyncAwaitAsynchronizer.async
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

                            guard let authenticatedConnection = try? NametagServerConnection(connection, logger) else
                            {
                                connection.close()
                                continue
                            }

                            acceptQueue.async
                            {
                                self.handleConnection(authenticatedConnection)
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

                func handleConnection(_ connection: AuthenticatedConnection)
                {
                    while self.running
                    {
                        do
                        {
                            guard let requestData = connection.network.readWithLengthPrefix(prefixSizeInBits: 64) else
                            {
                                throw \(className)ServerError.readFailed
                            }

                            print("Received a request:\\n\\(requestData.string)")

                            let decoder = \(decoder)()
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
                                let encoder = \(encoder)()
                                encoder.outputFormatting = .withoutEscapingSlashes
                                let responseData = try encoder.encode(response)
                                print("Sending a response:\\n\\(responseData.string)")
                                let _ = connection.network.writeWithLengthPrefix(data: responseData, prefixSizeInBits: 64)
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
        else
        {
            return """
            //
            //  \(className)Server.swift
            //
            //
            //  Created by Clockwork on \(dateString).
            //

            import Foundation

            import TransmissionTypes
            \(codableImports)
            \(importLines)

            public class \(className)Server
            {
                let listener: TransmissionTypes.Listener
                let handler: \(className)
                let acceptQueue = DispatchQueue(label: "SwitchboardAcceptQueue")
            
                var running: Bool = true

                public init(listener: TransmissionTypes.Listener, handler: \(className)) async
                {
                    self.listener = listener
                    self.handler = handler

                    await AsyncAwaitAsynchronizer.async
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

                            acceptQueue.async
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

                            let decoder = \(decoder)()
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
                                let encoder = \(encoder)()
                                encoder.outputFormatting = .withoutEscapingSlashes
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
    }

    func generateServerCases(_ className: String, _ functions: [Function], authenticateClient: Bool, format: SerializationFormat = .json) -> String
    {
        let cases = functions.map { self.generateServerCase(className, $0, authenticateClient: authenticateClient) }
        return cases.joined(separator: "\n")
    }

    func generateServerCase(_ className: String, _ function: Function, authenticateClient: Bool, format: SerializationFormat = .json) -> String
    {
        var publicKey = ""
        var connectionString = "connection"

        let encoder: String
        switch format
        {
            case .json:
                encoder = "JSONEncoder"

            case .cbor:
                encoder = "CBOREncoder"
        }

        if function.parameters.isEmpty
        {
            if authenticateClient
            {
                publicKey = "authenticatedConnectionPublicKey: connection.publicKey"
                connectionString = "connection.network"
            }

            if function.returnType == nil
            {
                if function.throwing
                {
                    return """
                                    case .\(function.name.capitalized)Request:
                                        try self.handler.\(function.name)(\(publicKey))
                                        let response = try \(className)Response.\(function.name.capitalized)Response
                                        let encoder = \(encoder)()
                                        encoder.outputFormatting = .withoutEscapingSlashes
                                        let responseData = try encoder.encode(response)
                                        print("Sending a response:\\n\\(responseData.string)")

                                        guard \(connectionString).writeWithLengthPrefix(data: responseData, prefixSizeInBits: 64) else
                                        {
                                            throw \(className)ServerError.writeFailed
                                        }
                """
                }
                else
                {
                    return """
                                    case .\(function.name.capitalized)Request:
                                        self.handler.\(function.name)(\(publicKey))
                                        let response = \(className)Response.\(function.name.capitalized)Response
                                        let encoder = \(encoder)()
                                        encoder.outputFormatting = .withoutEscapingSlashes
                                        let responseData = try encoder.encode(response)
                                        print("Sending a response:\\n\\(responseData.string)")

                                        guard \(connectionString).writeWithLengthPrefix(data: responseData, prefixSizeInBits: 64) else
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
                                        let result = try self.handler.\(function.name)(\(publicKey))
                                        let response = \(className)Response.\(function.name.capitalized)Response(value: result)
                                        let encoder = \(encoder)()
                                        encoder.outputFormatting = .withoutEscapingSlashes
                                        let responseData = try encoder.encode(response)
                                        print("Sending a response:\\n\\(responseData.string)")

                                        guard \(connectionString).writeWithLengthPrefix(data: responseData, prefixSizeInBits: 64) else
                                        {
                                            throw \(className)ServerError.writeFailed
                                        }
                """
                }
                else
                {
                    return """
                                    case .\(function.name.capitalized)Request:
                                        let result = self.handler.\(function.name)(\(publicKey)
                                        let response = \(className)Response.\(function.name.capitalized)Response(value: result)
                                        let encoder = \(encoder)()
                                        encoder.outputFormatting = .withoutEscapingSlashes
                                        let responseData = try encoder.encode(response)
                                        print("Sending a response:\\n\\(responseData.string)")

                                        guard \(connectionString).writeWithLengthPrefix(data: responseData, prefixSizeInBits: 64) else
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

            if authenticateClient
            {
                publicKey = "authenticatedConnectionPublicKey: connection.publicKey, "
                connectionString = "connection.network"
            }

            if function.returnType == nil
            {
                if function.throwing
                {
                    return """
                                    case .\(function.name.capitalized)Request(let value):
                                        try self.handler.\(function.name)(\(publicKey)\(argumentList))
                                        let response = \(className)Response.\(function.name.capitalized)Response
                                        let encoder = \(encoder)()
                                        encoder.outputFormatting = .withoutEscapingSlashes
                                        let responseData = try encoder.encode(response)
                                        print("Sending a response:\\n\\(responseData.string)")

                                        guard \(connectionString).writeWithLengthPrefix(data: responseData, prefixSizeInBits: 64) else
                                        {
                                            throw \(className)ServerError.writeFailed
                                        }
                """
                }
                else
                {
                    return """
                                    case .\(function.name.capitalized)Request(let value):
                                        self.handler.\(function.name)(\(publicKey)\(argumentList))
                                        let response = \(className)Response.\(function.name.capitalized)Response
                                        let encoder = \(encoder)()
                                        encoder.outputFormatting = .withoutEscapingSlashes
                                        let responseData = try encoder.encode(response)
                                        print("Sending a response:\\n\\(responseData.string)")

                                        guard \(connectionString).writeWithLengthPrefix(data: responseData, prefixSizeInBits: 64) else
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
                                        let result = try self.handler.\(function.name)(\(publicKey)\(argumentList))
                                        let response = \(className)Response.\(function.name.capitalized)Response(value: result)
                                        let encoder = \(encoder)()
                                        encoder.outputFormatting = .withoutEscapingSlashes
                                        let responseData = try encoder.encode(response)
                                        print("Sending a response:\\n\\(responseData.string)")

                                        guard \(connectionString).writeWithLengthPrefix(data: responseData, prefixSizeInBits: 64) else
                                        {
                                            throw \(className)ServerError.writeFailed
                                        }
                """
                }
                else
                {
                    return """
                                    case .\(function.name.capitalized)Request(let value):
                                        let result = self.handler.\(function.name)(\(publicKey)\(argumentList))
                                        let response = \(className)Response.\(function.name.capitalized)Response(value: result)
                                        let encoder = \(encoder)()
                                        encoder.outputFormatting = .withoutEscapingSlashes
                                        let responseData = try encoder.encode(response)
                                        print("Sending a response:\\n\\(responseData.string)")

                                        guard \(connectionString).writeWithLengthPrefix(data: responseData, prefixSizeInBits: 64) else
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
}
