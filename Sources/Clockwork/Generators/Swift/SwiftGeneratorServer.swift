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
            import Logging

            import TransmissionAsync
            import TransmissionAsyncNametag
            \(codableImports)
            \(importLines)

            public class \(className)Server
            {
                let listener: AsyncListener
                let handler: \(className)
                let logger: Logger

                var running: Bool = true

                public init(listener: AsyncListener, handler: \(className), logger: Logger) async
                {
                    self.listener = listener
                    self.handler = handler
                    self.logger = logger

                    await self.acceptLoop()
                }

                public func shutdown()
                {
                    self.running = false
                }

                func acceptLoop() async
                {
                    while self.running
                    {
                        do
                        {
                            let connection = try await self.listener.accept()

                            guard let authenticatedConnection = try? await AsyncNametagServerConnection(connection, logger) else
                            {
                                try? await connection.close()
                                continue
                            }

                            Task
                            {
                                try await self.handleConnection(authenticatedConnection)
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

                func handleConnection(_ connection: AsyncAuthenticatedConnection) async throws
                {
                    while self.running
                    {
                        do
                        {
                            let requestData = try await connection.network.readWithLengthPrefix(prefixSizeInBits: 64)

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
                                try await connection.network.writeWithLengthPrefix(responseData, 64)
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

            import TransmissionAsync
            \(codableImports)
            \(importLines)

            public class \(className)Server
            {
                let listener: TransmissionTypes.Listener
                let handler: \(className)

                var running: Bool = true

                public init(listener: AsyncListener, handler: \(className)) async
                {
                    self.listener = listener
                    self.handler = handler

                    await self.acceptLoop()
                }

                public func shutdown()
                {
                    self.running = false
                }

                func acceptLoop() async
                {
                    while self.running
                    {
                        do
                        {
                            let connection = try await self.listener.accept()

                            Task
                            {
                                try await self.handleConnection(connection)
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

                func handleConnection(_ connection: AsyncConnection) async throws
                {
                    while self.running
                    {
                        do
                        {
                            let requestData = try await connection.readWithLengthPrefix(prefixSizeInBits: 64)

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
                                let _ = try await connection.writeWithLengthPrefix(responseData, 64)
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

        let awaitText: String
        if function.async
        {
            awaitText = "await "
        }
        else
        {
            awaitText = ""
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
                                        let response = try \(awaitText)\(className)Response.\(function.name.capitalized)Response
                                        let encoder = \(encoder)()
                                        encoder.outputFormatting = .withoutEscapingSlashes
                                        let responseData = try encoder.encode(response)
                                        print("Sending a response:\\n\\(responseData.string)")

                                        try await \(connectionString).writeWithLengthPrefix(responseData, 64)
                """
                }
                else
                {
                    return """
                                    case .\(function.name.capitalized)Request:
                                        \(awaitText)self.handler.\(function.name)(\(publicKey))
                                        let response = \(className)Response.\(function.name.capitalized)Response
                                        let encoder = \(encoder)()
                                        encoder.outputFormatting = .withoutEscapingSlashes
                                        let responseData = try encoder.encode(response)
                                        print("Sending a response:\\n\\(responseData.string)")

                                        try await \(connectionString).writeWithLengthPrefix(responseData, 64) else
                """
                }
            }
            else
            {
                if function.throwing
                {
                    return """
                                    case .\(function.name.capitalized)Request:
                                        let result = try \(awaitText)self.handler.\(function.name)(\(publicKey))
                                        let response = \(className)Response.\(function.name.capitalized)Response(value: result)
                                        let encoder = \(encoder)()
                                        encoder.outputFormatting = .withoutEscapingSlashes
                                        let responseData = try encoder.encode(response)
                                        print("Sending a response:\\n\\(responseData.string)")

                                        try await \(connectionString).writeWithLengthPrefix(responseData, 64)
                """
                }
                else
                {
                    return """
                                    case .\(function.name.capitalized)Request:
                                        let result = \(awaitText)self.handler.\(function.name)(\(publicKey))
                                        let response = \(className)Response.\(function.name.capitalized)Response(value: result)
                                        let encoder = \(encoder)()
                                        encoder.outputFormatting = .withoutEscapingSlashes
                                        let responseData = try encoder.encode(response)
                                        print("Sending a response:\\n\\(responseData.string)")

                                        try await \(connectionString).writeWithLengthPrefix(responseData, 64)
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
                                        try \(awaitText)self.handler.\(function.name)(\(publicKey)\(argumentList))
                                        let response = \(className)Response.\(function.name.capitalized)Response
                                        let encoder = \(encoder)()
                                        encoder.outputFormatting = .withoutEscapingSlashes
                                        let responseData = try encoder.encode(response)
                                        print("Sending a response:\\n\\(responseData.string)")

                                        try await \(connectionString).writeWithLengthPrefix(responseData, 64)
                """
                }
                else
                {
                    return """
                                    case .\(function.name.capitalized)Request(let value):
                                        \(awaitText)self.handler.\(function.name)(\(publicKey)\(argumentList))
                                        let response = \(className)Response.\(function.name.capitalized)Response
                                        let encoder = \(encoder)()
                                        encoder.outputFormatting = .withoutEscapingSlashes
                                        let responseData = try encoder.encode(response)
                                        print("Sending a response:\\n\\(responseData.string)")

                                        try await \(connectionString).writeWithLengthPrefix(responseData, 64)
                """
                }
            }
            else
            {
                if function.throwing
                {
                    return """
                                    case .\(function.name.capitalized)Request(let value):
                                        let result = try \(awaitText)self.handler.\(function.name)(\(publicKey)\(argumentList))
                                        let response = \(className)Response.\(function.name.capitalized)Response(value: result)
                                        let encoder = \(encoder)()
                                        encoder.outputFormatting = .withoutEscapingSlashes
                                        let responseData = try encoder.encode(response)
                                        print("Sending a response:\\n\\(responseData.string)")

                                        try await \(connectionString).writeWithLengthPrefix(responseData, 64)
                """
                }
                else
                {
                    return """
                                    case .\(function.name.capitalized)Request(let value):
                                        let result = \(awaitText)self.handler.\(function.name)(\(publicKey)\(argumentList))
                                        let response = \(className)Response.\(function.name.capitalized)Response(value: result)
                                        let encoder = \(encoder)()
                                        encoder.outputFormatting = .withoutEscapingSlashes
                                        let responseData = try encoder.encode(response)
                                        print("Sending a response:\\n\\(responseData.string)")

                                        try await \(connectionString).writeWithLengthPrefix(responseData, 64)
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
