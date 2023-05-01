//
//  CppGeneratorUniverse.swift
//
//
//  Created by Dr. Brandon Wiley on 4/24/23.
//

import Foundation

extension CppGenerator
{
    public func generateUniverse(_ input: URL, _ output: URL)
    {
        do
        {
            let source = try String(contentsOf: input)
            let includeFile = input.lastPathComponent
            let className = try self.parser.findClassName(input, source)

            let functions = try self.parser.findFunctions(source)

            guard functions.count > 0 else
            {
                return
            }

            try self.generateUniverseHeader(output, includeFile, className, functions)
            try self.generateUniverse(output, className, functions)
        }
        catch
        {
            print(error)
        }
    }

    func generateUniverseHeader(_ outputURL: URL, _ includeFile: String, _ className: String, _ functions: [Function]) throws
    {
        print("Generating \(className)Universe.h...")

        let outputFile = outputURL.appending(component: "\(className)Universe.h")
        let result = try self.generateUniverseHeaderText(includeFile, className, functions)
        try result.write(to: outputFile, atomically: true, encoding: .utf8)
    }

    func generateUniverseHeaderText(_ includeFile: String, _ className: String, _ functions: [Function]) throws -> String
    {
        let date = Date() // now
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none

        let dateString = formatter.string(from: date)

        let universeName = self.makeUniverseName(className)
        let moduleName = self.makeModuleName(className)
        let functions = self.generateFunctionDeclarations(functions)

        return """
        //
        // \(universeName).h
        //
        //
        //  Created by Clockwork on \(dateString).
        //

        #ifndef \(className)Universe_h_
        #define \(className)Universe_h_

        #include "\(className)Messages.h"
        #include "\(className)Module.h"

        class \(universeName)
        {
            public:
                \(universeName)(\(moduleName) *handler) : module(handler) {}

                \(moduleName) *module;

        \(functions)
        };

        #endif
        """
    }

    func generateFunctionDeclarations(_ functions: [Function]) -> String
    {
        let results = functions.compactMap { self.generateFunctionDeclaration($0) }
        return results.joined(separator: "\n")
    }

    func generateFunctionDeclaration( _ function: Function) -> String
    {
        let returnTypeText: String
        if let returnType = function.returnType
        {
            returnTypeText = returnType
        }
        else
        {
            returnTypeText = "void"
        }

        let parameterText: String
        if function.parameters.isEmpty
        {
            parameterText = ""
        }
        else
        {
            let parameters = function.parameters.map { self.generateParameter($0) }
            parameterText = parameters.joined(separator: ", ")
        }

        return "        \(returnTypeText) \(function.name)(\(parameterText));"
    }

    func generateUniverse(_ outputURL: URL, _ className: String, _ functions: [Function]) throws
    {
        let universeName = self.makeUniverseName(className)
        print("Generating \(universeName).cpp...")

        let outputFile = outputURL.appending(component: "\(universeName).cpp")
        let result = try self.generateUniverseText(className, functions)
        try result.write(to: outputFile, atomically: true, encoding: .utf8)
    }

    func generateUniverseText(_ className: String, _ functions: [Function]) throws -> String
    {
        let date = Date() // now
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none

        let dateString = formatter.string(from: date)

        let universeName = self.makeUniverseName(className)
        let functions = self.generateFunctions(className, functions)

        return """
        //
        //  \(universeName).cpp
        //
        //
        //  Created by Clockwork on \(dateString).
        //

        #include "\(universeName).h"

        \(functions)
        """
    }

    func generateFunctions(_ className: String, _ functions: [Function]) -> String
    {
        let results = functions.compactMap { self.generateFunction(className, $0) }
        return results.joined(separator: "\n\n")
    }

    func generateFunction(_ className: String, _ function: Function) -> String
    {
        let signature = self.generateFunctionSignature(className, function)
        let body = self.generateFunctionBody(className, function)
        let lines: [String] = body.split(separator: "\n").map { String($0) }.filter
        {
            line in

            return !line.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        let trimmedBody = lines.joined(separator: "\n")

        return """
        \(signature)
        {
        \(trimmedBody)
        }
        """
    }

    func generateFunctionSignature(_ className: String, _ function: Function) -> String
    {
        let universeName = self.makeUniverseName(className)

        let returnTypeText: String
        if let returnType = function.returnType
        {
            returnTypeText = returnType
        }
        else
        {
            returnTypeText = "void"
        }

        let parameterText: String
        if function.parameters.isEmpty
        {
            parameterText = ""
        }
        else
        {
            let parameters = function.parameters.map { self.generateParameter($0) }
            parameterText = parameters.joined(separator: ", ")
        }

        return "\(returnTypeText) \(universeName)::\(function.name)(\(parameterText))"
    }

    func generateParameter(_ parameter: FunctionParameter) -> String
    {
        return "\(parameter.type) \(parameter.name)"
    }

    func generateFunctionBody(_ className: String, _ function: Function) -> String
    {
        let requestName = self.makeRequestName(className)
        let requestEnumCaseName = self.generateRequestTypeEnum(className, function)
        let requestCaseName = self.makeRequestCaseName(className, function)
        let responseName = self.makeResponseName(className)
        let responseCaseName = self.makeResponseCaseName(className, function)
        let errorName = self.makeErrorName(className)

        let requestBodyInit: String
        let requestBodyParameter: String
        let requestBodyDelete: String
        if function.parameters.isEmpty
        {
            requestBodyInit = ""
            requestBodyParameter = "NULL"
            requestBodyDelete = ""
        }
        else
        {
            let arguments = function.parameters.map { self.generateArgument($0) }
            let argumentList = arguments.joined(separator: ", ")

            requestBodyInit = """
            \(requestCaseName) *requestBody = new \(requestCaseName)(\(argumentList));
            """

            requestBodyParameter = "(void *)requestBody"
            requestBodyDelete = """
            delete requestBody;
            """
        }

        let responseCast: String
        let returnValue: String
        let deleteResponseBody: String
        let returnHandler: String
        if let returnType = function.returnType
        {
            responseCast = "\(responseCaseName) *result = (\(responseCaseName) *)response->body;"
            returnValue = "\(returnType) returnValue = result->value; // Because this is a value type, this will be a copy."
            deleteResponseBody = "delete result;"
            returnHandler = "return returnValue;"
        }
        else
        {
            responseCast = ""
            returnValue = ""
            deleteResponseBody = ""
            returnHandler = ""
        }

        return """
            \(requestBodyInit)
            \(requestName) *request = new \(requestName)(\(requestEnumCaseName), \(requestBodyParameter));
            \(responseName) *response = this->module->handle(request);

            if (response->type == \(errorName))
            {
                Serial.println("ERROR in \(className).\(function.name)(). Program halted.");
                while(1)
                {
                    // We can't return because we don't have a valid return value, so we enter an infinite loop instead.
                }
            }

            \(responseCast)
            \(returnValue)
            delete request;
            \(requestBodyDelete)
            \(deleteResponseBody)
            delete response;
            \(returnHandler)
        """
    }

    func generateArgument(_ argument: FunctionParameter) -> String
    {
        return "\(argument.name)"
    }
}
