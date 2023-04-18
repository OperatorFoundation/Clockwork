//
//  CGeneratorMessages.swift
//  
//
//  Created by Dr. Brandon Wiley on 4/13/23.
//

import Foundation

extension CGenerator
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

        let requestEnums = self.generateRequestEnumsText(className, functions)
        let responseEnums = self.generateResponseEnumsText(className, functions)

        return """
        //
        //  \(className)Messages.h
        //
        //
        //  Created by Clockwork on \(dateString).
        //

        typedef struct \(className)Error
        {
          char *message;
        } \(className)Error_t;

        typedef struct \(className)Request
        {
            int type;
            void *body;
        } \(className)Request_t;

        typedef struct \(className)Response
        {
            int type;
            void *body;
        } \(className)Response_t;

        \(requestEnums)

        \(responseEnums)
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
        let typeEnums = functions.map { self.generateTypeEnum($0) }
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
        let typeEnums = functions.map { self.generateTypeEnum($0) }
        return "enum \(className)ResponseType {\(typeEnums.joined(separator: ", "))};"
    }

    func generateTypeEnum(_ function: Function) -> String
    {
        return function.name.uppercased()
    }

    func generateRequestEnumCase(_ className: String, _ function: Function) -> String?
    {
        if function.parameters.isEmpty
        {
            return nil
        }
        else
        {
            let requestParameters = generateRequestParameters(function)
            return """
            typedef struct \(function.name.capitalized)Request
            {
            \(requestParameters)
            } \(function.name.capitalized)Request_t;
            """
        }
    }

    func generateResponseEnumCase(_ className: String, _ function: Function) -> String?
    {
        if let returnType = function.returnType
        {
            return """
            typedef struct \(function.name.capitalized)Response
            {
                \(returnType) \(function.name)
            } \(function.name.capitalized)Response_t;
            """
        }
        else
        {
            return nil
        }
    }
}
