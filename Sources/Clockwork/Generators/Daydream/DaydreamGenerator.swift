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
        namespace.`enum`("Boolean", ["True", "False"])
        namespace.list("ListVarint", "Varint")

        namespace.builtin("Int", "Varint")
        namespace.builtin("Bool", "Boolean")
        namespace.builtin("Data", "ListVarint")
        namespace.builtin("Text", "ListVarint")
        namespace.builtin("String", "ListVarint")

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
                argumentsTypeName = function.parameters[0].type.text

                if argumentsTypeName.startsWith("inout ")
                {
                    continue
                }

                if argumentsTypeName.containsSubstring("?")
                {
                    continue
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
                    else
                    {
                        argument = parameter.type.text
                    }

                    arguments.append(argument)
                }

                argumentsTypeName = "\(function.name)_arguments".text
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
                    // f()
                    namespace.singleton(function.name.text)
                }
                else
                {
                    // f() -> T
                    let returnTypeName = "\(function.name.text)_return".text
                    namespace.record(returnTypeName, [returnType])
                    namespace.record(function.name.text, [returnTypeName])
                }
            }
            else
            {
                if returnType == "Nothing"
                {
                    // f(T)
                    if arguments.isEmpty
                    {
                        namespace.record(function.name.text, [argumentsTypeName])
                    }
                    else
                    {
                        namespace.record(argumentsTypeName, arguments)
                        namespace.record(function.name.text, [argumentsTypeName])
                    }
                }
                else
                {
                    // f(S) -> T
                    let returnTypeName = "\(function.name.text)_return".text
                    namespace.record(returnTypeName, [returnType])

                    if arguments.isEmpty
                    {
                        namespace.record(function.name.text, [argumentsTypeName, returnTypeName])
                    }
                    else
                    {
                        namespace.record(argumentsTypeName, arguments)
                        namespace.record(function.name.text, [argumentsTypeName, returnTypeName])
                    }
                }
            }

            functionNames.append(function.name.text)
        }

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
