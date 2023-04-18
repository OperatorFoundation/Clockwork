//
//  CGeneratorServer.swift
//  
//
//  Created by Dr. Brandon Wiley on 4/13/23.
//

import Foundation

extension CGenerator
{
    public func generateServer(_ input: URL, _ output: URL)
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

            try self.generateServerHeader(output, className, functions)
            try self.generateServer(output, className, functions)
        }
        catch
        {
            print(error)
        }
    }

    func generateServerHeader(_ outputURL: URL, _ className: String, _ functions: [Function]) throws
    {
        print("Generating \(className)Server.h...")

        let outputFile = outputURL.appending(component: "\(className)Server.h")
        let result = try self.generateServerHeaderText(className, functions)
        try result.write(to: outputFile, atomically: true, encoding: .utf8)
    }

    func generateServerHeaderText(_ className: String, _ functions: [Function]) throws -> String
    {
        let date = Date() // now
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none

        let dateString = formatter.string(from: date)

        let cases = self.generateServerCases(className, functions)

        return """
        //
        // \(className)Server.h
        //
        //
        //  Created by Clockwork on \(dateString).
        //

        void \(className)ServerInit(int listener, 
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


    func generateServer(_ outputURL: URL, _ className: String, _ functions: [Function]) throws
    {
        print("Generating \(className)Server.c...")

        let outputFile = outputURL.appending(component: "\(className)Server.c")
        let result = try self.generateServerText(className, functions)
        try result.write(to: outputFile, atomically: true, encoding: .utf8)
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
        #  \(className)Server.c
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

}
