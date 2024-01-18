//
//  CppParser.swift
//  
//
//  Created by Dr. Brandon Wiley on 4/4/23.
//

import Foundation

public class CppParser: Parser
{
    public required init()
    {
    }

    public func findImports(_ source: String) throws -> [String]
    {
        let regex = try Regex("#include [<\"][A-Za-z0-9]+[>\"]")
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
        let afterPublic = String(source.components(separatedBy: "public:")[1])

        let publicSource: String
        if afterPublic.contains("private:")
        {
            publicSource = String(source.components(separatedBy: "private:")[0])
        }
        else
        {
            publicSource = afterPublic
        }

        let regex = try Regex("^[ \\t]*[A-Za-z0-9_]+ [A-Za-z0-9_]+(.+)$")
        let lines = publicSource.components(separatedBy: "\n").map { String($0) }
        let goodLines = lines.filter
        {
            line in

            let range = line.ranges(of: regex)
            return range.count > 0
        }

        let goodParts = goodLines.map
        {
            goodLine in

            let parts = goodLine.components(separatedBy: " def ")
            return parts[1]
        }

        return goodParts.compactMap
        {
            function in

            do
            {
                let name = try self.findFunctionName(function)
                let parameters = try self.findParameters(function)
                let returnType = try self.findFunctionReturnType(function)
                let throwing = try self.findFunctionThrowing(function)
                return Function(name: name, parameters: parameters, returnType: returnType, throwing: throwing)
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
        let parts = prefix.split(separator: ",").map { String($0) }
        return try parts
        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        .compactMap
        {
            part in

            let subparts = part.split(separator: " ")
            guard subparts.count == 2 else
            {
                throw ClockworkError.badFunctionFormat
            }

            let type = String(subparts[0])
            let name = String(subparts[1])
            return FunctionParameter(name: name, type: type, elide: true)
        }
    }

    public func findFunctionReturnType(_ function: String) throws -> String?
    {
        let returnTypeAndName = String(function.split(separator: "(")[0])

        guard returnTypeAndName.contains(" ") else
        {
            return nil
        }

        return String(returnTypeAndName.split(separator: " ")[0])
    }

    public func findFunctionThrowing(_ function: String) throws -> Bool
    {
        return false
    }
}
