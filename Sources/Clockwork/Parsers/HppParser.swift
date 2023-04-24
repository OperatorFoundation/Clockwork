//
//  HppParser.swift
//  
//
//  Created by Dr. Brandon Wiley on 4/13/23.
//

import Foundation

import Text

public class HppParser: Parser
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
        let text = Text(fromUTF8String: source)

        let classLine = try text.substringRegex(try Regex("class [A-Za-z0-9]+"))
        let (_, className) = try classLine.splitOn(" ") // Discard the "class " part
        return className.toUTF8String()
    }

    public func findFunctions(_ source: String) throws -> [Function]
    {
        let mtext = MutableText(fromUTF8String: source)

        try mtext.becomeSplitOnTail("public:") // We want only the part after "public:"
        try? mtext.becomeSplitOnHead("private:") // If there is a private: section, trim it off.
        try? mtext.becomeSplitOnHead("protected:") // If there is a protected: section, trim it off.

        let publicSource: Text = mtext.toText()

        let regex = try Regex("^[ \\t]*[A-Za-z0-9_ ]+ [A-Za-z0-9_]+\\(.+\\)[ \\t]*[;{](//.*)?$")
        let lines = publicSource.split("\n")
        let goodLines = lines.filter
        {
            line in

            line.containsRegex(regex)
        }

        let functions: [Function] = goodLines.compactMap
        {
            functionText in

            if functionText.containsSubstring("__attribute__")
            {
                // Not actually a functiony
                return nil
            }

            if functionText.containsSubstring("*")
            {
                // No pointers allowed
                return nil
            }

            do
            {
                let name = try self.findFunctionName(functionText)
                let parameters = try self.findParameters(functionText)
                let returnType = try self.findFunctionReturnType(functionText)
                return Function(name: name, parameters: parameters, returnType: returnType, throwing: false)
            }
            catch
            {
                return nil
            }
        }

        var seenEnums: Set<String> = Set<String>()
        let uniqueFunctions: [Function] = functions.filter
        {
            function in

            let enumName = function.name.capitalized
            let seen = seenEnums.contains(enumName)
            seenEnums.insert(enumName)
            return !seen
        }

        return uniqueFunctions
    }

    func findFunctionName(_ function: Text) throws -> String
    {
        let mtext: MutableText = MutableText(fromText: function)
        try mtext.becomeSplitOnHead("(") // Left of the (
        try mtext.becomeSplitOnLastTail(" ") // Right of the space
        return mtext.toUTF8String()
    }

    func findParameters(_ function: Text) throws -> [FunctionParameter]
    {
        let mtext: MutableText = MutableText(fromText: function)
        try mtext.becomeSplitOnTail("(") // Right of the (
        try mtext.becomeSplitOnHead(")") // Left of the )

        if mtext.isEmpty()
        {
            return []
        }

        return mtext.split(", ").compactMap
        {
            part in

            do
            {
                let (type, name) = try part.splitOnLast(" ") // We must split on the last space for types such as "unsigned int"

                let mtype = MutableText(fromText: type)
                let mname = MutableText(fromText: name)

                if mname.startsWith("*")
                {
                    mtype.becomeAppended("*")
                    try mname.becomeDropFirst()
                }

                return FunctionParameter(name: mname.toUTF8String(), type: mtype.toUTF8String())
            }
            catch
            {
                return nil
            }
        }
    }

    func findFunctionReturnType(_ function: Text) throws -> String?
    {
        let mtext: MutableText = MutableText(fromText: function)
        try mtext.becomeSplitOnHead("(")

        let (type, name) = try mtext.splitOnLast(" ")
        let mtype: MutableText = MutableText(fromText: type)
        mtype.becomeTrimmed()

        if name.startsWith("*")
        {
            mtype.becomeAppended("*")
        }

        guard mtype != "void" else // A void return type in C++ means the function does not return anything, which we signify here with nil.
        {
            return nil
        }

        if mtype.containsSubstring("virtual")
        {
            throw HppParserError.noVirtualFunctionsAllowed
        }

        return mtype.toUTF8String()
    }
}

public enum HppParserError: Error
{
    case noVirtualFunctionsAllowed
}
