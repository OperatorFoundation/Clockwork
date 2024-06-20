//
//  SwiftParser.swift
//
//
//  Created by Dr. Brandon Wiley on 2/19/23.
//

import Foundation

public class SwiftParser: Parser
{
    required public init()
    {
    }

    public func findImports(_ source: String) throws -> [String]
    {
        let regex = try Regex("import [A-Za-z0-9]+")
        return source.ranges(of: regex).map
        {
            range in

            let substring = source[range].split(separator: " ")[1]
            return String(substring)
        }
    }

    public func findClassName(_ sourceURL: URL, _ source: String) throws -> String
    {
        let regex = try Regex("class [A-Za-z0-9]+")
        let ranges = source.ranges(of: regex)
        guard ranges.count == 1 else
        {
            if ranges.count == 0
            {
                throw ClockworkSpacetimeError.noMatches
            }
            else
            {
                throw ClockworkSpacetimeError.tooManyMatches
            }
        }

        return String(source[ranges[0]].split(separator: " ")[1])
    }

    public func findSuperclassNames(_ source: String, _ className: String) throws -> [String]?
    {
        // FIXME
        return nil
    }

    public func findFunctions(_ source: String) throws -> [Function]
    {
        let regex = try Regex("public func [A-Za-z0-9]+\\([^\\)]*\\)( async)?( throws)?( -> [(), A-Za-z0-9\\[\\]<>]+[?]?)?")
        let lines = source.split(separator: "\n").map { String($0) }
        let results: [String] = lines.compactMap
        {
            line in

            if line.contains(" static ")
            {
                return nil
            }

            let ranges = line.ranges(of: regex)
            guard ranges.count == 1 else
            {
                return nil
            }

            let range = ranges[0]

            let substrings = line[range].split(separator: " ")[2...]
            let strings = substrings.map { String($0) }
            return strings.joined(separator: " ")
        }

        return results.compactMap
        {
            function in

            do
            {
                let name = try self.findFunctionName(function)
                let parameters = try self.findParameters(function)
                let returnType = try self.findFunctionReturnType(function)
                let throwing = try self.findFunctionThrowing(function)
                let async = try self.findFunctionAsync(function)
                return Function(name: name, parameters: parameters, returnType: returnType, throwing: throwing, async: async)
            }
            catch
            {
                return nil
            }
        }
    }

    public func findFunctionName(_ function: String) throws -> String
    {
        return String(function.split(separator: "(")[0])
    }

    public func findParameters(_ function: String) throws -> [FunctionParameter]
    {
        guard function.firstIndex(of: "@") == nil else
        {
            throw ClockworkSpacetimeError.badFunctionFormat
        }

        guard !function.contains("<") else
        {
            throw ClockworkSpacetimeError.badFunctionFormat
        }

        guard let parameterStart = function.firstIndex(of: "(") else
        {
            throw ClockworkSpacetimeError.badFunctionFormat
        }

        guard let parameterEnd = function.firstIndex(of: ")") else
        {
            throw ClockworkSpacetimeError.badFunctionFormat
        }

        if function.index(after: parameterStart) == parameterEnd
        {
            return []
        }

        let suffix = String(function.split(separator: "(")[1])
        let prefix = String(suffix.split(separator: ")")[0])
        let parts = prefix.split(separator: ", ").map { String($0) }
        let parameters = try parts.map
        {
            part in

            let subparts = part.split(separator: ": ")
            guard subparts.count == 2 else
            {
                throw ClockworkError.badFunctionFormat
            }

            var name = String(subparts[0])
            var elide = false
            if name.starts(with: "_ ")
            {
                name = String(name.dropFirst().dropFirst())
                elide = true
            }

            var type = String(subparts[1])
            if type.contains("=")
            {
                let subparts = type.split(separator: "=")
                type = String(subparts[0]).trimmingCharacters(in: .whitespacesAndNewlines)
            }
            return FunctionParameter(name: name, type: type, elide: elide)
        }
        
        return parameters.filter
        {
            parameter in
            
            return parameter.name != "authenticatedConnectionPublicKey"
        }
    }

    public func findFunctionReturnType(_ function: String) throws -> String?
    {
        guard function.firstIndex(of: "-") != nil else
        {
            return nil
        }

        let result = String(function.split(separator: "-> ")[1])

        if result.contains("(")
        {
            throw SwiftParserError.unsupportedReturnType
        }

        return result
    }

    public func findFunctionThrowing(_ function: String) throws -> Bool
    {
        if let last = function.split(separator: " ").last
        {
            if last == "throws"
            {
                return true
            }
        }

        return function.split(separator: " throws ").count == 2
    }

    public func findFunctionAsync(_ function: String) throws -> Bool
    {
        return function.split(separator: " ").contains("async")
    }
}

public enum SwiftParserError: Error
{
    case unsupportedReturnType
}
