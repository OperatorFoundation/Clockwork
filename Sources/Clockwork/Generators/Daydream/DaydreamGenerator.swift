//
//  DaydreamGenerator.swift
//
//
//  Created by Dr. Brandon Wiley on 12/30/23.
//

import ArgumentParser
import Foundation

import Daydream
import Gardener
import Text

public class DaydreamGenerator
{
    let parser: any Parser

    public init(parser: any Parser)
    {
        self.parser = parser
    }

    public func generate(_ input: URL, _ output: URL)
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

            let saveURL = output.appendingPathComponent("\(className).daydream")

            let extracted = ExtractedInterface(className: className, functions: functions)
            let namespace = convert(extracted)
            try namespace.validate()
            try namespace.save(saveURL)
        }
        catch
        {
            print(error)
        }
    }

    func convert(_ extracted: ExtractedInterface) -> Namespace
    {
        let namespace = Namespace()

        namespace.singletons("Nothing", "True", "False", "Varint")
        namespace.`enum`("Boolean", "True", "False")
        namespace.list("ListVarint", "Varint")

        namespace.builtin("Int", "Varint")
        namespace.builtin("Bool", "Boolean")
        namespace.builtin("Data", "ListVarint")
        namespace.builtin("Text", "ListVarint")
        namespace.builtin("String", "ListVarint")
        namespace.record("Error", "String")

        var functionNames: [Text] = []

        for function in extracted.functions
        {
            let argumentsTypeName: Text
            var arguments: [Text] = []
            if function.parameters.isEmpty
            {
                argumentsTypeName = "Nothing".text
            }
            else if function.parameters.count == 1
            {
                let typeName = function.parameters[0].type.text

                if typeName.startsWith("inout ")
                {
                    continue
                }

                if typeName.string.hasPrefix("[")
                {
                    let coreName = String(typeName.string.dropFirst().dropLast())
                    let listTypeName = "\(coreName)List"
                    namespace.list(listTypeName.text, coreName.text)

                    argumentsTypeName = listTypeName.text
                }
                else if typeName.string.hasSuffix("?")
                {
                    let coreName = String(typeName.string.dropLast()).text
                    let enumTypeName = "Maybe\(coreName)".text
                    namespace.enum(enumTypeName, coreName, "Nothing")

                    argumentsTypeName = enumTypeName
                }
                else
                {
                    argumentsTypeName = typeName
                }
            }
            else
            {
                for parameter in function.parameters
                {
                    let argument: Text
                    if parameter.type.hasPrefix("[")
                    {
                        let coreName = String(parameter.type.dropFirst().dropLast())
                        let listTypeName = "\(coreName)List"
                        namespace.list(listTypeName.text, coreName.text)

                        argument = listTypeName.text
                    }
                    else if parameter.type.hasSuffix("?")
                    {
                        let coreName = String(parameter.type.dropLast()).text
                        let enumTypeName = "Maybe\(coreName)".text
                        namespace.enum(enumTypeName, coreName, "Nothing")

                        argument = enumTypeName
                    }
                    else
                    {
                        argument = parameter.type.text
                    }

                    arguments.append(argument)
                }

                argumentsTypeName = "\(function.name)_arguments".text
                namespace.record(argumentsTypeName, arguments)
            }

            let returnType: Text
            if let functionReturnType = function.returnType
            {
                if functionReturnType.hasPrefix("[")
                {
                    let coreName = String(functionReturnType.dropFirst().dropLast())
                    let listTypeName = "\(coreName)List"
                    namespace.list(listTypeName.text, coreName.text)

                    returnType = listTypeName.text
                }
                else if functionReturnType.hasSuffix("?")
                {
                    let coreName = String(functionReturnType.dropLast()).text
                    let enumTypeName = "Maybe\(coreName)".text
                    namespace.enum(enumTypeName, coreName, "Nothing")

                    returnType = enumTypeName
                }
                else
                {
                    returnType = functionReturnType.text
                }
            }
            else
            {
                returnType = "Nothing".text
            }

            if argumentsTypeName == "Nothing"
            {
                if returnType == "Nothing"
                {
                    if function.throwing
                    {
                        // f() throws
                        namespace.singleton("\(function.name)_request".text)
                        namespace.`enum`("\(function.name)_response".text, returnType, "Error")
                    }
                    else
                    {
                        // f()
                        namespace.singleton("\(function.name)_request".text)
                        namespace.singleton("\(function.name)_response".text)
                    }
                }
                else
                {
                    if function.throwing
                    {
                        // f() throws -> T
                        namespace.singleton("\(function.name)_request".text)
                        namespace.record("\(function.name)_response_value".text, returnType)
                        namespace.`enum`("\(function.name)_response".text, "\(function.name)_response_value".text, "Error")
                    }
                    else
                    {
                        // f() -> T
                        namespace.singleton("\(function.name)_request".text)
                        namespace.record("\(function.name)_response".text, returnType)
                    }
                }
            }
            else
            {
                if returnType == "Nothing"
                {
                    if function.throwing
                    {
                        // f(T) throws
                        namespace.record("\(function.name)_request".text, argumentsTypeName)
                        namespace.`enum`("\(function.name)_response".text, returnType, "Error")
                    }
                    else
                    {
                        // f(T)
                        namespace.record("\(function.name)_request".text, argumentsTypeName)
                        namespace.singleton("\(function.name)_response".text)
                    }
                }
                else
                {
                    if function.throwing
                    {
                        // f(S) throws -> T
                        namespace.record("\(function.name)_request".text, argumentsTypeName)
                        namespace.`enum`("\(function.name)_response".text, "\(function.name)_response_value".text, "Error")
                        namespace.record("\(function.name)_response_value".text, returnType)
                    }
                    else
                    {
                        // f(S) -> T
                        namespace.record("\(function.name)_request".text, argumentsTypeName)
                        namespace.record("\(function.name)_response".text, "\(function.name)_response_value".text)
                        namespace.record("\(function.name)_response_value".text, returnType)
                    }
                }
            }

            functionNames.append(function.name.text)
        }

        let _ = functionNames.map
        {
            functionName in

            namespace.singleton(functionName)
        }

        let requestNames = functionNames.map { "\($0)_request".text }
        namespace.`enum`("\(extracted.className)Request".text, requestNames)

        let responseNames = functionNames.map { "\($0)_response".text }
        namespace.`enum`("\(extracted.className)Response".text, responseNames)

        namespace.`enum`(extracted.className.text, functionNames)

        return namespace
    }
}

public enum DaydreamGeneratorError: Error
{
    case sourcesDirectoryDoesNotExist
    case noMatches
    case tooManyMatches
    case badFunctionFormat
    case noOutputDirectory
    case templateNotFound
}
