//
//  CppGeneratorMessages.swift
//
//
//  Created by Dr. Brandon Wiley on 4/13/23.
//

import Foundation

extension CppGenerator
{
    public func generateMessages(_ input: URL, _ output: URL)
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

            try self.generateMessages(output, className, functions)
        }
        catch
        {
            print(error)
        }
    }

    func generateMessages(_ outputURL: URL, _ className: String, _ functions: [Function]) throws
    {
        print("Generating \(className)Messages.h...")

        let outputFile = outputURL.appending(component: "\(className)Messages.h")
        let result = try self.generateMessagesText(className, functions)
        try result.write(to: outputFile, atomically: true, encoding: .utf8)
    }

    func generateMessagesText(_ className: String, _ functions: [Function]) throws -> String
    {
        let date = Date() // now
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none

        let dateString = formatter.string(from: date)

        let requestName = self.makeRequestName(className)
        let responseName = self.makeResponseName(className)
        let requestEnums = self.generateRequestEnumsText(className, functions)
        let responseEnums = self.generateResponseEnumsText(className, functions)

        return """
        //
        //  \(className)Messages.h
        //
        //
        //  Created by Clockwork on \(dateString).
        //

        #ifndef \(className)Messages_h_
        #define \(className)Messages_h_

        #include <Arduino.h>

        class \(requestName)
        {
            public:
                \(requestName)(int type, void *body)
                {
                    this->type = type;
                    this->body = body;
                }

                int type;
                void *body;
        };

        class \(responseName)
        {
            public:
                \(responseName)(int type, void *body)
                {
                    this->type = type;
                    this->body = body;
                }

                int type;
                void *body;
        };

        \(requestEnums)

        \(responseEnums)

        #endif
        """
    }

    func generateRequestEnumsText(_ className: String, _ functions: [Function]) -> String
    {
        let typeEnum = generateRequestTypeEnums(className, functions)
        let enums = functions.compactMap { self.generateRequestEnumCase(className, $0) }
        return typeEnum + "\n\n" + enums.joined(separator: "\n\n")
    }

    func generateRequestTypeEnums(_ className: String, _ functions: [Function]) -> String
    {
        let typeEnums = functions.map { self.generateRequestTypeEnum(className, $0) }
        return "enum \(className)RequestType {\(typeEnums.joined(separator: ", "))};"
    }

    func generateResponseEnumsText(_ className: String, _ functions: [Function]) -> String
    {
        let typeEnum = generateResponseTypeEnums(className, functions)
        let enums = functions.compactMap { self.generateResponseEnumCase(className, $0) }
        return typeEnum + "\n\n" + enums.joined(separator: "\n\n")
    }

    func generateResponseTypeEnums(_ className: String, _ functions: [Function]) -> String
    {
        let responseName = self.makeResponseName(className)
        let typeEnums = ["\(responseName)_ERROR"] + functions.map { self.generateResponseTypeEnum(className, $0) }
        return "enum \(className)ResponseType {\(typeEnums.joined(separator: ", "))};"
    }

    func generateRequestTypeEnum(_ className: String, _ function: Function) -> String
    {
        let requestName = self.makeRequestName(className)
        return "\(requestName)_\(function.name.uppercased())"
    }

    func generateResponseTypeEnum(_ className: String, _ function: Function) -> String
    {
        let responseName = self.makeResponseName(className)
        return "\(responseName)_\(function.name.uppercased())"
    }

    func generateRequestEnumCase(_ className: String, _ function: Function) -> String?
    {
        if function.parameters.isEmpty
        {
            return nil
        }
        else
        {
            let requestClassName = self.makeRequestCaseName(className, function)
            let constructorParams = self.generateRequestConstructorParameters(function)
            let requestSetters = generateRequestSetters(function)
            let requestParameters = generateRequestEnumParameters(function)

            return """
            class \(requestClassName)
            {
                public:
                    \(requestClassName)(\(constructorParams))
                    {
            \(requestSetters)
                    }

            \(requestParameters)
            };
            """
        }
    }

    func generateRequestEnumParameters(_ function: Function) -> String
    {
        let enums = function.parameters.map { self.generateRequestEnumParameter($0) }
        return enums.joined(separator: "\n")
    }

    func generateRequestEnumParameter(_ parameter: FunctionParameter) -> String
    {
        return "        \(parameter.type) \(parameter.name);"
    }

    func generateRequestConstructorParameters(_ function: Function) -> String
    {
        let enums = function.parameters.map { self.generateRequestConstructorParameter($0) }
        return enums.joined(separator: ", ")
    }

    func generateRequestConstructorParameter(_ parameter: FunctionParameter) -> String
    {
        return "\(parameter.type) \(parameter.name)"
    }

    func generateRequestSetters(_ function: Function) -> String
    {
        let enums = function.parameters.map { self.generateRequestSetter($0) }
        return enums.joined(separator: "\n")
    }

    func generateRequestSetter(_ parameter: FunctionParameter) -> String
    {
        return "            this->\(parameter.name) = \(parameter.name);"
    }

    func generateResponseEnumCase(_ className: String, _ function: Function) -> String?
    {
        let responseCaseName = self.makeResponseCaseName(className, function)

        if let returnType = function.returnType
        {
            return """
            class \(responseCaseName)
            {
                public:
                    \(responseCaseName)(\(returnType) value)
                    {
                        // value is a value type and not a pointer, so this->value should be a copy.
                        this->value = value;
                    }

                    \(returnType) value;
            };
            """
        }
        else
        {
            return nil
        }
    }
}
