//
//  ClockworkKotlin.swift
//
//
//  Created by Dr. Brandon Wiley on 2/15/23.
//

import ArgumentParser
import Foundation

import Gardener

public class KotlinGenerator
{
    let parser: any Parser

    public init(parser: any Parser)
    {
        self.parser = parser
    }

    public func generateMessages(_ input: URL, _ output: URL, _ package: String?)
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

            try self.generateMessages(output, className, functions, package)
        }
        catch
        {
            print(error)
        }
    }

    public func generateClient(_ input: URL, _ output: URL, _ package: String?)
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

            try self.generateClient(output, className, functions, package)
        }
        catch
        {
            print(error)
        }
    }

    func generateMessages(_ outputURL: URL, _ className: String, _ functions: [Function], _ package: String?) throws
    {
        print("Generating \(className)Messages.kt...")

        let outputFile = outputURL.appending(component: "\(className)Messages.kt")
        let result = try self.generateRequestText(className, functions, package)
        try result.write(to: outputFile, atomically: true, encoding: .utf8)
    }

    func generateClient(_ outputURL: URL, _ className: String, _ functions: [Function], _ package: String?) throws
    {
        print("Generating \(className)Client.kt...")

        let outputFile = outputURL.appending(component: "\(className)Client.kt")
        let result = try self.generateClientText(className, functions, package)
        try result.write(to: outputFile, atomically: true, encoding: .utf8)
    }

    func generateRequestText(_ className: String, _ functions: [Function], _ package: String?) throws -> String
    {
        let date = Date() // now
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none

        let dateString = formatter.string(from: date)

        let packageDefinition: String
        if let package
        {
            packageDefinition = "package \(package)"
        }
        else
        {
            packageDefinition = ""
        }

        let requestEnums = self.generateRequestEnumsText(className, functions)
        let requestEnumTypes = self.generateTypeEnumsText(functions, isRequest: true)
        let responseEnums = try self.generateResponseEnumsText(className, functions)
        let responseEnumTypes = self.generateTypeEnumsText(functions, isRequest: false)

        return """
        //
        //  \(className)Messages.kt
        //
        //
        //  Created by Clockwork on \(dateString).
        //

        \(packageDefinition)

        import kotlinx.serialization.Serializable

        @Serializable data class \(className)Error(override val message: String): Exception()
        {
            override fun toString(): String
            {
                return "\(className)Error: " + this.message
            }
        }
        
        enum class \(className)RequestTypes(val value: Int) {
        \(requestEnumTypes)
        }

        sealed class \(className)Request {
        \(requestEnums)
        }
        
        enum class \(className)ResponseTypes(val value: Int) {
        \(responseEnumTypes)
        }

        sealed class \(className)Response {
        \(responseEnums)
        }
        """
    }

    func generateClientText(_ className: String, _ functions: [Function],  _ package: String?) throws -> String
    {
        let date = Date() // now
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none

        let dateString = formatter.string(from: date)

        let packageDefinition: String
        if let package
        {
            packageDefinition = "package \(package)"
        }
        else
        {
            packageDefinition = ""
        }
        let functions = try self.generateFunctions(className, functions)

        return """
        //
        //  \(className)Client.kt
        //
        //
        //  Created by Clockwork on \(dateString).
        //

        \(packageDefinition)

        import kotlinx.serialization.json.Json
        import kotlinx.serialization.encodeToString
        import kotlinx.serialization.decodeFromString

        import org.operatorfoundation.transmission.Connection

        class \(className)Client(val connection: Connection)
        {
        \(functions)
        }

        class \(className)ConnectionRefusedException(): Exception()
        {
        }

        class \(className)WriteFailedException(): Exception()
        {
        }

        class \(className)ReadFailedException(): Exception()
        {
        }

        class \(className)BadReturnTypeException(): Exception()
        {
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
            return "    @Serializable data class \(function.name.capitalized)Request() : \(className)Request()"
        }
        else
        {
            let requestParameters = generateRequestParameters(function)
            return "    @Serializable data class \(function.name.capitalized)Request(\(requestParameters)) : \(className)Request()"
        }
    }
    
    func generateTypeEnumsText(_ functions: [Function], isRequest request: Bool) -> String
    {
        var enumCases = [String]()
        
        for (index, element) in functions.enumerated()
        {
            enumCases.append(self.generateTypeEnumCase(element, isRequest: request) + "(\(index))")
        }

        return enumCases.joined(separator: ",\n")
    }
    
    func generateTypeEnumCase(_ function: Function, isRequest request: Bool) -> String
    {
        if request
        {
            return "    \(function.name.capitalized)Request"
        }
        else
        {
            return "    \(function.name.capitalized)Response"
        }
    }

    func generateResponseEnumsText(_ className: String, _ functions: [Function]) throws -> String
    {
        let enums = try functions.map { try self.generateResponseEnumCase(className, $0) }
        return enums.joined(separator: "\n")
    }

    func generateResponseEnumCase(_ className: String, _ function: Function) throws -> String
    {
        if let returnType = function.returnType
        {
            return "    @Serializable data class \(function.name.capitalized)Response(val value: \(kotlinizeType(returnType))) : \(className)Response()"
        }
        else
        {
            return "    @Serializable data class \(function.name.capitalized)Response() : \(className)Response()"
        }
    }

    func generateRequestParameters(_ function: Function) -> String
    {
        let enums = function.parameters.map { self.generateRequestParameter($0) }
        return enums.joined(separator: ", ")
    }

    func generateRequestParameter(_ parameter: FunctionParameter) -> String
    {
        return "val \(parameter.name): \(kotlinizeType(parameter.type))"
    }

    func generateParameter(_ parameter: FunctionParameter) -> String
    {
        return "\(parameter.name): \(kotlinizeType(parameter.type))"
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
            return "    @Synchronized fun \(function.name)(\(parameterList)) : \(kotlinizeType(returnType))"
        }
        else
        {
            return "    @Synchronized fun \(function.name)(\(parameterList))"
        }
    }

    func generateFunctionBody(_ className: String, _ function: Function, includeDefault: Bool) -> String
    {
        let structHandler: String
        if function.parameters.isEmpty
        {
            structHandler = "()"
        }
        else
        {
            let arguments = function.parameters.map { self.generateArgument($0) }
            let argumentList = arguments.joined(separator: ", ")
            structHandler = "(\(argumentList))"
        }

        let returnHandler: String
        if function.returnType == nil
        {
            returnHandler = """
            return
            """
        }
        else
        {
            returnHandler = """
            return response.value
            """
        }

        return """
            {
                val message = \(className)Request.\(function.name.capitalized)Request\(structHandler)
                val jsonString = Json.encodeToString(message)
                val normalizedJsonString = "{\\"\(function.name.capitalized)Request\\":{\\"_${\(className)RequestTypes.\(function.name.capitalized)Request.value}\\":$jsonString}}"
                val data = normalizedJsonString.toByteArray()
        
                if (!this.connection.writeWithLengthPrefix(data, 64))
                {
                    throw \(className)WriteFailedException()
                }

                val responseData = this.connection.readWithLengthPrefix(64)
                if (responseData == null)
                {
                    throw \(className)ReadFailedException()
                }

                try
                {
                    val normalizedJSONString = responseData.decodeToString()
                    val firstColonIndex = normalizedJSONString.indexOf(":")

                    if (firstColonIndex < 0)
                    {
                        throw Exception("invalidJson")
                    }

                    val secondColonIndex = normalizedJSONString.indexOf(":", firstColonIndex + 1)
                    val denormalizedJSONString = normalizedJSONString.slice(secondColonIndex + 1 until normalizedJSONString.length - 2)
                    val response = Json.decodeFromString<\(className)Response.\(function.name.capitalized)Response>(denormalizedJSONString)
        
                    \(returnHandler)
                }
                catch(error: Exception)
                {
                    try
                    {
                        val errorResponse = Json.decodeFromString<\(className)Error>(responseData.decodeToString())
                        throw errorResponse
                    }
                    catch(error: Exception)
                    {
                        throw \(className)BadReturnTypeException()
                    }
                }
            }
        """

    }

    func generateArgument(_ argument: FunctionParameter) -> String
    {
        return "\(argument.name)"
    }

    func generateKotlinMessages(_ outputURL: URL, _ className: String, _ functions: [Function], _ package: String?) throws
    {
        print("Generating \(className)Messages.kt...")

        let outputFile = outputURL.appending(component: "\(className)Messages.kt")
        let result = try self.generateRequestText(className, functions, package)
        try result.write(to: outputFile, atomically: true, encoding: .utf8)
    }

    func generateKotlintClient(_ outputURL: URL, _ className: String, _ functions: [Function], _ package: String?) throws
    {
        print("Generating \(className)Client.kt...")

        let outputFile = outputURL.appending(component: "\(className)Client.kt")
        let result = try self.generateClientText(className, functions, package)
        try result.write(to: outputFile, atomically: true, encoding: .utf8)
    }

    func kotlinizeType(_ type: String) -> String
    {
        if type[type.startIndex] == "["
        {
            let start = type.index(after: type.startIndex)
            let end = type.index(before: type.endIndex)

            let innerType = type[start..<end]
            return "Array<\(innerType)>"
        }
        else
        {
            return type
        }
    }
}

public enum ClockworkKotlinError: Error
{
    case emptyParameters
    case sourcesDirectoryDoesNotExist
    case noMatches
    case tooManyMatches
    case badFunctionFormat
    case noOutputDirectory
    case templateNotFound
}
