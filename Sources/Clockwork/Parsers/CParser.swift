////
////  CParser.swift
////
////
////  Created by Dr. Brandon Wiley on 3/11/23.
////
//
//import Foundation
//
//public class CParser: Parser
//{
//    public required init()
//    {
//    }
//
//    public func findImports(_ source: String) throws -> [String]
//    {
//        let regex = try Regex("#include [<\"][A-Za-z0-9]+[>\"]")
//        return source.ranges(of: regex).map
//        {
//            range in
//
//            let substring = source[range].split(separator: " ")[1]
//            return String(substring)
//        }
//    }
//
//    public func findClassName(_ sourceURL: URL) throws -> String
//    {
//        return sourceURL.deletingPathExtension().lastPathComponent
//    }
//
//    public func findFunctions(_ source: String) throws -> [Function]
//    {
//        let regex = try Regex("^[ \\t]*[A-Za-z0-9_]+ [A-Za-z0-9_]+(.+);$")
//        let lines = source.components(separatedBy: "\n").map { String($0) }
//        let goodLines = lines.filter
//        {
//            line in
//
//            let range = line.ranges(of: regex)
//            return range.count > 0
//        }
//
//        let goodParts = goodLines.map
//        {
//            goodLine in
//
//            let parts = goodLine.components(separatedBy: " def ")
//            return parts[1]
//        }
//
//        return goodParts.compactMap
//        {
//            function in
//
//            do
//            {
//                let name = try self.findFunctionName(function)
//                let parameters = try self.findParameters(function)
//                let returnType = try self.findFunctionReturnType(function)
//                let throwing = try self.findFunctionThrowing(function)
//                return Function(name: name, parameters: parameters, returnType: returnType, throwing: throwing)
//            }
//            catch
//            {
//                return nil
//            }
//        }
//    }
//
//    public func findFunctionName(_ function: String) throws -> String
//    {
//        return String(function.split(separator: "(")[0])
//    }
//
//    public func findParameters(_ function: String) throws -> [FunctionParameter]
//    {
//        guard function.firstIndex(of: "@") == nil else
//        {
//            throw ClockworkSpacetimeError.badFunctionFormat
//        }
//
//        guard function.firstIndex(of: "_") == nil else
//        {
//            throw ClockworkSpacetimeError.badFunctionFormat
//        }
//
//        guard let parameterStart = function.firstIndex(of: "(") else
//        {
//            throw ClockworkSpacetimeError.badFunctionFormat
//        }
//
//        guard let parameterEnd = function.firstIndex(of: ")") else
//        {
//            throw ClockworkSpacetimeError.badFunctionFormat
//        }
//
//        if function.index(after: parameterStart) == parameterEnd
//        {
//            return []
//        }
//
//        let suffix = String(function.split(separator: "(")[1])
//        let prefix = String(suffix.split(separator: ")")[0])
//        let parts = prefix.split(separator: ", ").map { String($0) }
//        return try parts.compactMap
//        {
//            part in
//
//            guard part != "self" else
//            {
//                return nil
//            }
//
//            let subparts = part.split(separator: ": ")
//            guard subparts.count == 2 else
//            {
//                throw ClockworkError.badFunctionFormat
//            }
//
//            let name = String(subparts[0])
//            let type = String(subparts[1])
//            return FunctionParameter(name: name, type: type)
//        }
//    }
//
//    public func findFunctionReturnType(_ function: String) throws -> String?
//    {
//        guard function.firstIndex(of: "-") != nil else
//        {
//            return nil
//        }
//
//        return String(function.split(separator: "-> ")[1])
//    }
//
//    public func findFunctionThrowing(_ function: String) throws -> Bool
//    {
//        return true
//    }
//}
