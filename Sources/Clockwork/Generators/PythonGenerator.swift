//
//  ClockworkPython.swift
//
//
//  Created by Dr. Brandon Wiley on 2/15/23.
//

import ArgumentParser
import Foundation

import Gardener

public class PythonGenerator
{
    let parser: any Parser

    public init(parser: any Parser)
    {
        self.parser = parser
    }

    public func generateMessages(_ input: URL, _ output: URL)
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

            try self.generateMessages(output, className, functions)
        }
        catch
        {
            print(error)
        }
    }

    public func generateClient(_ input: URL, _ output: URL)
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

            try self.generateClient(output, className, functions)
        }
        catch
        {
            print(error)
        }
    }

    public func generateServer(_ input: URL, _ output: URL)
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

            try self.generateServer(output, className, functions)
        }
        catch
        {
            print(error)
        }
    }

    func generateMessages(_ outputURL: URL, _ className: String, _ functions: [Function]) throws
    {
        print("Generating \(className)Messages.py...")

        let outputFile = outputURL.appending(component: "\(className)Messages.py")
        let result = try self.generateRequestText(className, functions)
        try result.write(to: outputFile, atomically: true, encoding: .utf8)
    }

    func generateClient(_ outputURL: URL, _ className: String, _ functions: [Function]) throws
    {
        print("Generating \(className)Client.py...")

        let outputFile = outputURL.appending(component: "\(className)Client.py")
        let result = try self.generateClientText(className, functions)
        try result.write(to: outputFile, atomically: true, encoding: .utf8)
    }

    func generateServer(_ outputURL: URL, _ className: String, _ functions: [Function]) throws
    {
        print("Generating \(className)Server.py...")

        let outputFile = outputURL.appending(component: "\(className)Server.py")
        let result = try self.generateServerText(className, functions)
        try result.write(to: outputFile, atomically: true, encoding: .utf8)
    }

    func generateRequestText(_ className: String, _ functions: [Function]) throws -> String
    {
        let date = Date() // now
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none

        let dateString = formatter.string(from: date)

        let requestEnums = self.generateRequestEnumsText(className, functions)
        let responseEnums = try self.generateResponseEnumsText(className, functions)

        return """
        #
        #  \(className)Messages.py
        #
        #
        #  Created by Clockwork on \(dateString).
        #

        class \(className)Error(Exception):
            def __init__(message: String):
                self.message = message

        class \(className)Request:
            pass

        \(requestEnums)

        class \(className)Response:
            pass

        \(responseEnums)
        """
    }

    func generateClientText(_ className: String, _ functions: [Function]) throws -> String
    {
        let date = Date() // now
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none

        let dateString = formatter.string(from: date)

        let functions = try self.generateFunctions(className, functions)

        return """
        #
        #  \(className)Client.py
        #
        #
        #  Created by Clockwork on \(dateString).
        #

        from transmission import Connection

        class \(className)Client:
            def __init__(self, connection):
                self.connection = connection

        \(functions)
        """
    }

    func generateServerText(_ className: String, _ functions: [Function]) throws -> String
    {
        let date = Date() // now
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none

        let dateString = formatter.string(from: date)

        let cases = self.generateServerCases(className, functions)

        return """
        #
        #  \(className)Server.py
        #
        #
        #  Created by Clockwork on \(dateString).
        #

        class \(className)Server:
            def __init__(self, listener, handler):
                self.listener = listener
                self.handler = handler

                self.accept()

            def shutdown(self):
                pass

            def accept(self):
                connection = self.listener.accept()
                self.handleConnection(connection)

            def handleConnection(self, connection):
                try:
                    request = connection.read(\(className)Response)
                    if not request:
                        raise Exception("request read failed")

        \(cases)
                except Exception as e:
                    print(e)

                    error = \(className)Error(str(e))
                    try:
                        connection.write(error)
                    except Exception as e2:
                        print(e2)

                    return
        """
    }

    func generateRequestEnumsText(_ className: String, _ functions: [Function]) -> String
    {
        let enums = functions.map { self.generateRequestEnumCase(className, $0) }
        return enums.joined(separator: "\n\n")
    }

    func generateRequestEnumCase(_ className: String, _ function: Function) -> String
    {
        if function.parameters.isEmpty
        {
            return """
            class \(function.name.capitalized)Request(\(className.capitalized)Request):
                pass
            """
        }
        else
        {
            let requestParameters = generateRequestParameters(function)
            let inits = generateInits(function.parameters)
            return """
            class \(function.name.capitalized)Request(\(className.capitalized)Request):
                def __init__(self, \(requestParameters)):
            \(inits)
            """
        }
    }

    func generateServerCases(_ className: String, _ functions: [Function]) -> String
    {
        let cases = functions.map { self.generateServerCase(className, $0) }
        return cases.joined(separator: "\n\n")
    }

    func generateServerCase(_ className: String, _ function: Function) -> String
    {
        if function.parameters.isEmpty
        {
            if function.returnType == nil
            {
                if function.throwing
                {
                    return """
                                if isinstance(request, \(className)\(function.name.capitalized)Request):
                                    self.handler.\(function.name)()
                                    response = \(className)\(function.name.capitalized)Response()
                                    self.connection.write(response)
                    """
                }
                else
                {
                    return """
                                if isinstance(request, \(className)\(function.name.capitalized)Request):
                                    self.handler.\(function.name)()
                                    response = \(className)\(function.name.capitalized)Response()
                                    self.connection.write(response)
                    """
                }
            }
            else
            {
                if function.throwing
                {
                    return """
                                if isinstance(request, \(className)\(function.name.capitalized)Request):
                                    result = self.handler.\(function.name)()
                                    response = \(className)\(function.name.capitalized)Response(result)
                                    self.connection.write(response)
                    """
                }
                else
                {
                    return """
                                if isinstance(request, \(className)\(function.name.capitalized)Request):
                                    result = self.handler.\(function.name)()
                                    response = \(className)\(function.name.capitalized)Response(result)
                                    self.connection.write(response)
                    """
                }
            }
        }
        else
        {
            let arguments = function.parameters.map { self.generateServerArgument($0) }
            let argumentList = arguments.joined(separator: ", ")

            if function.returnType == nil
            {
                if function.throwing
                {
                    return """
                                if isinstance(request, \(function.name.capitalized)):
                                    self.handler.\(function.name)(\(argumentList))
                                    response = \(className)\(function.name.capitalized)Response()
                                    self.connection.write(response)
                    """
                }
                else
                {
                    return """
                                if isinstance(request, \(function.name.capitalized)):
                                    self.handler.\(function.name)(\(argumentList))
                                    response = \(className)\(function.name.capitalized)Response()
                                    self.connection.write(response)
                    """
                }
            }
            else
            {
                if function.throwing
                {
                    return """
                                if isinstance(request, \(function.name.capitalized)):
                                    result = self.handler.\(function.name)(\(argumentList))
                                    response = \(className)\(function.name.capitalized)Response(result)
                                    self.connection.write(response)
                    """
                }
                else
                {
                    return """
                                if isinstance(request, \(function.name.capitalized)):
                                    result = self.handler.\(function.name)(\(argumentList))
                                    response = \(className)\(function.name.capitalized)Response(result)
                                    self.connection.write(response)
                    """
                }
            }
        }
    }

    func generateServerArgument(_ parameter: FunctionParameter) -> String
    {
        return "\(parameter.name)"
    }

    func generateInits(_ parameters: [FunctionParameter]) -> String
    {
        let inits = parameters.map { self.generateInit($0) }
        return inits.joined(separator: "\n")
    }

    func generateInit(_ parameter: FunctionParameter) -> String
    {
        return "        self.\(parameter.name) = \(parameter.name)"
    }

    func generateResponseEnumsText(_ className: String, _ functions: [Function]) throws -> String
    {
        let enums = try functions.map { try self.generateResponseEnumCase(className, $0) }
        return enums.joined(separator: "\n\n")
    }

    func generateResponseEnumCase(_ className: String, _ function: Function) throws -> String
    {
        if function.returnType != nil
        {
            return """
            class \(function.name.capitalized)Response(\(className.capitalized)Response):
                def __init__(self, value):
                    self.value = value
            """
        }
        else
        {
            return """
            class \(function.name.capitalized)Response(\(className.capitalized)Response):
                pass
            """
        }
    }

    func generateRequestParameters(_ function: Function) -> String
    {
        let enums = function.parameters.map { self.generateRequestParameter($0) }
        return enums.joined(separator: ", ")
    }

    func generateRequestParameter(_ parameter: FunctionParameter) -> String
    {
        return "\(parameter.name)"
    }

    func generateParameter(_ parameter: FunctionParameter) -> String
    {
        return "\(parameter.name)"
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
        if function.parameters.isEmpty
        {
            return "    def \(function.name)(self):"
        }
        else
        {
            let parameters = function.parameters.map { self.generateParameter($0) }
            let parameterList = parameters.joined(separator: ", ")

            return "    def \(function.name)(self, \(parameterList)):"
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
                    if isinstance(response, \(function.name.capitalized)Response):
                        return
            """
        }
        else
        {
            returnHandler = """
                    if isistance(response, \(function.name.capitalized)Response):
                        return response.value
            """
        }

        let defaultHandler: String
        if includeDefault
        {
            defaultHandler = """
                    else:
                        raise Exception("bad return type")
            """
        }
        else
        {
            defaultHandler = ""
        }

        return """
                message = \(function.name.capitalized)Request\(structHandler)
                if not self.connection.write(message):
                    raise Exception("write failed")

                response = self.connection.read()
                if not response:
                    raise Exception("read failed")

        \(returnHandler)
        \(defaultHandler)
        """

    }

    func generateArgument(_ argument: FunctionParameter) -> String
    {
        return "\(argument.name)"
    }

    func generatePythonMessages(_ outputURL: URL, _ className: String, _ functions: [Function]) throws
    {
        print("Generating \(className)Messages.py...")

        let outputFile = outputURL.appending(component: "\(className)Messages.py")
        let result = try self.generateRequestText(className, functions)
        try result.write(to: outputFile, atomically: true, encoding: .utf8)
    }

    func generatePythontClient(_ outputURL: URL, _ className: String, _ functions: [Function]) throws
    {
        print("Generating \(className)Client.py...")

        let outputFile = outputURL.appending(component: "\(className)Client.py")
        let result = try self.generateClientText(className, functions)
        try result.write(to: outputFile, atomically: true, encoding: .utf8)
    }
}

public enum ClockworkPythonError: Error
{
    case emptyParameters
    case sourcesDirectoryDoesNotExist
    case noMatches
    case tooManyMatches
    case badFunctionFormat
    case noOutputDirectory
    case templateNotFound
}
