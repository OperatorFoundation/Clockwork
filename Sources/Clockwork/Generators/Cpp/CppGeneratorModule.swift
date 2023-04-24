//
//  CppGeneratorModule.swift
//
//
//  Created by Dr. Brandon Wiley on 4/21/23.
//

import Foundation

extension CppGenerator
{
    public func generateModule(_ input: URL, _ output: URL)
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

            try self.generateModuleHeader(output, includeFile, className, functions)
            try self.generateModule(output, className, functions)
        }
        catch
        {
            print(error)
        }
    }

    func generateModuleHeader(_ outputURL: URL, _ includeFile: String, _ className: String, _ functions: [Function]) throws
    {
        print("Generating \(className)Module.h...")

        let outputFile = outputURL.appending(component: "\(className)Module.h")
        let result = try self.generateModuleHeaderText(includeFile, className, functions)
        try result.write(to: outputFile, atomically: true, encoding: .utf8)
    }

    func generateModuleHeaderText(_ includeFile: String, _ className: String, _ functions: [Function]) throws -> String
    {
        let date = Date() // now
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none

        let dateString = formatter.string(from: date)

        let handlerName = self.makeHandlerName(className)
        let requestName = self.makeRequestName(className)
        let responseName = self.makeResponseName(className)

        return """
        //
        // \(className)Module.h
        //
        //
        //  Created by Clockwork on \(dateString).
        //

        #include "\(includeFile)"
        #include "\(className)Messages.h"

        class \(handlerName)
        {
            public:
                \(handlerName)(\(className) logic)
                {
                    this.logic = logic;
                }

                \(className) logic;
                \(responseName) handle(\(requestName) request);
        }
        """
    }


    func generateModule(_ outputURL: URL, _ className: String, _ functions: [Function]) throws
    {
        print("Generating \(className)Module.cpp...")

        let outputFile = outputURL.appending(component: "\(className)Module.cpp")
        let result = try self.generateModuleText(className, functions)
        try result.write(to: outputFile, atomically: true, encoding: .utf8)
    }

    func generateModuleText(_ className: String, _ functions: [Function]) throws -> String
    {
        let date = Date() // now
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none

        let dateString = formatter.string(from: date)

        let handlerName = self.makeHandlerName(className)
        let requestName = self.makeRequestName(className)
        let responseName = self.makeResponseName(className)
        let cases = self.generateModuleCases(className, functions)

        return """
        //
        //  \(className)Module.cpp
        //
        //
        //  Created by Clockwork on \(dateString).
        //

        #include "\(className)Module.h"

        \(responseName) \(handlerName)::handle(\(requestName) request)
        {
            switch (request.type)
            {
        \(cases)
            }

            return returnValue;
        }
        """
    }

    func generateModuleCases(_ className: String, _ functions: [Function]) -> String
    {
        let cases = functions.map { self.generateModuleCase(className, $0) }
        return cases.joined(separator: "\n\n")
    }

    func generateModuleCase(_ className: String, _ function: Function) -> String
    {
        let caseName = self.generateTypeEnum(function)
        let requestName = self.makeRequestCaseName(className, function)
        let responseName = self.makeResponseName(className)
        let responseCaseName = self.makeResponseCaseName(className, function)
        let methodName = self.makeMethodName(className, function)

        let setResult: String
        let makeResponse: String
        let resultParameter: String
        if let returnType = function.returnType
        {
            setResult = "\(returnType) result = "
            makeResponse = "\(responseCaseName) response = \(responseCaseName)(result);"
            resultParameter = "(void *)&response"
        }
        else
        {
            setResult = ""
            makeResponse = ""
            resultParameter = "NULL"
        }

        let parameters: String = self.generateModuleArguments(function.parameters)

        let parametersCast: String
        if function.parameters.isEmpty
        {
            parametersCast = ""
        }
        else
        {
            parametersCast = "\n            \(requestName) parameters = (\(requestName) *)request.body;"
        }

        return """
                case \(caseName):\(parametersCast)
                    \(setResult)this.logic.\(methodName)(\(parameters))
                    \(makeResponse)
                    return new \(responseName)(\(caseName), \(resultParameter));
        """
    }

    func generateModuleArguments(_ parameters: [FunctionParameter]) -> String
    {
        let arguments = parameters.map { self.generateModuleArgument($0) }
        return arguments.joined(separator: ", ")
    }

    func generateModuleArgument(_ parameter: FunctionParameter) -> String
    {
        return "parameters->\(parameter.name)"
    }
}
