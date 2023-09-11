//
//  SwiftGeneratorClient.swift
//  
//
//  Created by Dr. Brandon Wiley on 7/17/23.
//

import Foundation

extension SwiftGenerator
{
    public func generateClient(_ input: URL, _ output: URL, authenticateClient: Bool, format: SerializationFormat = .json)
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

            try self.generateClient(output, imports, className, functions, authenticateClient: authenticateClient, format: format)
        }
        catch
        {
            print(error)
        }
    }

    func generateClient(_ outputURL: URL, _ imports: [String], _ className: String, _ functions: [Function], authenticateClient: Bool, format: SerializationFormat = .json) throws
    {
        print("Generating \(className)Client.swift...")

        let outputFile = outputURL.appending(component: "\(className)Client.swift")
        let result = try self.generateClientText(imports, className, functions, authenticateClient: authenticateClient, format: format)
        try result.write(to: outputFile, atomically: true, encoding: .utf8)
    }

    func generateClientText(_ imports: [String], _ className: String, _ functions: [Function], authenticateClient: Bool, format: SerializationFormat = .json) throws -> String
    {
        let date = Date() // now
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none

        let dateString = formatter.string(from: date)

        let functions = try self.generateFunctions(className, functions)
        var firstImportLines = "import TransmissionTypes"
        var classPropertyLines = """
                let connection: TransmissionTypes.Connection
                let lock = DispatchSemaphore(value: 1)
            """

        if authenticateClient
        {
            firstImportLines = """
            #if os(macOS)
            import os.log
            #else
            import Logging
            #endif

            import TransmissionNametag
            import TransmissionTypes
            """
            
            classPropertyLines = """
                public let publicKey: PublicKey
                let connection: TransmissionTypes.Connection
                let lock = DispatchSemaphore(value: 1)
            """
        }
        let importLines = self.generateImports(imports)

        let codableImports: String
        switch format
        {
            case .cbor:
                codableImports = """
                import PotentCodables
                """

            default:
                codableImports = ""
        }

        return """
        //
        //  \(className)Client.swift
        //
        //
        //  Created by Clockwork on \(dateString).
        //

        import Foundation

        \(firstImportLines)
        \(codableImports)
        import \(className)
        \(importLines)

        public class \(className)Client
        {
        \(classPropertyLines)

        \(generateClientInit(authenticateClient: authenticateClient))

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

    func generateClientInit(authenticateClient: Bool) -> String
    {
        if authenticateClient
        {
            return """
                public init(connection: AuthenticatingConnection, keychain: KeychainProtocol, logger: Logger) throws
                {
                    self.connection = connection.network
                    self.publicKey = connection.publicKey
                }
            """
        }
        else
        {
            return """
                public init(connection: TransmissionTypes.Connection)
                {
                    self.connection = connection
                }
            """
        }
    }

    func generateFunctions(_ className: String, _ functions: [Function], format: SerializationFormat = .json) throws -> String
    {
        let results = try functions.compactMap { try self.generateFunction(className, $0, includeDefault: functions.count > 1) }
        return results.joined(separator: "\n\n")
    }

    func generateFunction(_ className: String, _ function: Function, includeDefault: Bool, format: SerializationFormat = .json) throws -> String
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

    func generateFunctionBody(_ className: String, _ function: Function, includeDefault: Bool, format: SerializationFormat = .json) -> String
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

        let encoder: String
        let decoder: String
        switch format
        {
            case .json:
                encoder = "JSONEncoder"
                decoder = "JSONDecoder"

            case .cbor:
                encoder = "CBOREncoder"
                decoder = "CBORDecoder"
        }

        return """
            {
                defer
                {
                    self.lock.signal()
                }
                self.lock.wait()

                let message = \(className)Request.\(function.name.capitalized)Request\(structHandler)
                let encoder = \(encoder)()
                encoder.outputFormatting = .withoutEscapingSlashes
                let data = try encoder.encode(message)
                guard self.connection.writeWithLengthPrefix(data: data, prefixSizeInBits: 64) else
                {
                    throw \(className)ClientError.writeFailed
                }

                guard let responseData = self.connection.readWithLengthPrefix(prefixSizeInBits: 64) else
                {
                    throw \(className)ClientError.readFailed
                }

                let decoder = \(decoder)()

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
}
