//
//  Interactions.swift
//  
//
//  Created by Dr. Brandon Wiley on 1/8/23.
//

import Foundation

extension ClockworkSpacetime
{
    public func generateInteractionsFile(_ input: URL, _ output: URL)
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

            let outputFile = output.appending(component: "\(className)Interactions.swift")
            try self.generateInteractions(outputFile, className, functions)
        }
        catch
        {
            print(error)
        }
    }

    func generateInteractions(_ outputURL: URL, _ className: String, _ functions: [Function]) throws
    {
        print("Generating \(outputURL)...")

        let outputFile = outputURL.appending(component: "\(className)Interactions.swift")
        let result = try self.generateInteractionsSource(className, functions)
        try result.write(to: outputFile, atomically: true, encoding: .utf8)
    }

    func generateInteractionsSource(_ className: String, _ functions: [Function]) throws -> String
    {
        let date = Date() // now
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none

        let dateString = formatter.string(from: date)

        let functionInteractions = self.generateFunctionInteractions(className, functions)

        return """
        //
        //  \(className)Interactions.swift
        //
        //
        //  Created by ClockworkSpacetime on \(dateString).
        //

        import Foundation

        import Spacetime

        public class \(className)Effect: Effect
        {
            enum CodingKeys: String, CodingKey
            {
                case id
            }

            public init()
            {
                super.init(module: "\(className)")
            }

            public init(id: UUID)
            {
                super.init(id: id, module: "\(className)")
            }

            public required init(from decoder: Decoder) throws
            {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                let id = try container.decode(UUID.self, forKey: .id)

                super.init(id: id, module: "\(className)")
            }
        }

        public class \(className)Event: Event
        {
            enum CodingKeys: String, CodingKey
            {
                case effectId
            }

            public init(_ effectId: UUID)
            {
                super.init(effectId, module: "\(className)")
            }

            public required init(from decoder: Decoder) throws
            {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                let effectId = try container.decode(UUID.self, forKey: .effectId)

                super.init(effectId, module: "\(className)")
            }
        }

        \(functionInteractions)
        """
    }

    public func generateFunctionInteractions(_ className: String, _ functions: [Function]) -> String
    {
        let enums = functions.map { self.generateFunctionInteraction(className, $0) }
        return enums.joined(separator: "\n\n")
    }

    public func generateFunctionInteraction(_ className: String, _ function: Function) -> String
    {
        let effect: String
        if function.parameters.isEmpty
        {
            effect = """
            public class \(className)\(function.name.capitalizingFirstLetter())Request: \(className)Effect
            {
                enum CodingKeys: String, CodingKey
                {
                    case id
                }

                public override init()
                {
                    super.init()
                }

                public override init(id: UUID)
                {
                    super.init(id: id)
                }

                public required init(from decoder: Decoder) throws
                {
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                    let id = try container.decode(UUID.self, forKey: .id)

                    super.init(id: id)
                }
            }
            """
        }
        else
        {
            let effectArguments = self.generateEffectArguments(function)
            let effectCodingKeys = self.generateEffectCodingKeys(function)
            let effectSetters = self.generateEffectSetters(function)
            let effectFields = self.generateStructFields(function)
            let effectDecoders = self.generateEffectDecoders(function)

            effect = """
            public class \(className)\(function.name.capitalizingFirstLetter())Request: \(className)Effect
            {
            \(effectFields)

                enum CodingKeys: String, CodingKey
                {
                    case id
            \(effectCodingKeys)
                }

                public init(\(effectArguments))
                {
            \(effectSetters)

                    super.init()
                }

                public init(id: UUID, \(effectArguments))
                {
            \(effectSetters)

                    super.init(id: id)
                }

                public required init(from decoder: Decoder) throws
                {
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                    let id = try container.decode(UUID.self, forKey: .id)
            \(effectDecoders)

            \(effectSetters)
                    super.init(id: id)
                }
            }
            """
        }

        let event: String
        if let returnType = function.returnType
        {
            event = """
            public class \(className)\(function.name.capitalizingFirstLetter())Response: \(className)Event
            {
                public let result: \(returnType)

                enum CodingKeys: String, CodingKey
                {
                    case effectId
                    case result
                }

                public init(_ effectId: UUID, _ result: \(returnType))
                {
                    self.result = result

                    super.init(effectId)
                }

                public required init(from decoder: Decoder) throws
                {
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                    let effectId = try container.decode(UUID.self, forKey: .effectId)
                    let result = try container.decode(\(returnType).self, forKey: .result)

                    self.result = result
                    super.init(effectId)
                }
            }
            """
        }
        else
        {
            event = """
            public class \(className)\(function.name.capitalizingFirstLetter())Response: \(className)Event
            {
                enum CodingKeys: String, CodingKey
                {
                    case effectId
                }

                public override init(_ effectId: UUID)
                {
                    super.init(effectId)
                }

                public required init(from decoder: Decoder) throws
                {
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                    let effectId = try container.decode(UUID.self, forKey: .effectId)

                    super.init(effectId)
                }
            }
            """
        }

        return """
        \(effect)

        \(event)
        """
    }

    public func generateEffectArguments(_ function: Function) -> String
    {
        let arguments = function.parameters.map { self.generateEffectArgument($0) }
        let argumentList = arguments.joined(separator: ", ")
        return argumentList
    }

    public func generateEffectArgument(_ parameter: FunctionParameter) -> String
    {
        return "\(parameter.name): \(parameter.type)"
    }

    public func generateEffectSetters(_ function: Function) -> String
    {
        let setters = function.parameters.map { self.generateInit($0) }
        return setters.joined(separator: "\n")
    }

    public func generateEffectInits(_ function: Function) -> String
    {
        let setters = function.parameters.map { self.generateEffectInit($0) }
        return setters.joined(separator: ", ")
    }

    public func generateEffectCodingKeys(_ function: Function) -> String
    {
        let codingKeys = function.parameters.map { self.generateCodingKey($0) }
        return codingKeys.joined(separator: "\n")
    }

    public func generateCodingKey(_ parameter: FunctionParameter) -> String
    {
        return "        case \(parameter.name)"
    }

    func generateStructFields(_ function: Function) -> String
    {
        let fields = function.parameters.map { self.generateStructField($0) }
        let fieldList = fields.joined(separator: "\n")
        return fieldList
    }

    func generateStructField(_ parameter: FunctionParameter) -> String
    {
        return "    public let \(parameter.name): \(parameter.type)"
    }

    func generateEffectDecoders(_ function: Function) -> String
    {
        let fields = function.parameters.map { self.generateEffectDecoder($0) }
        let fieldList = fields.joined(separator: "\n")
        return fieldList
    }

    func generateEffectDecoder(_ parameter: FunctionParameter) -> String
    {
        return "        let \(parameter.name): \(parameter.type) = try container.decode(\(parameter.type).self, forKey: .\(parameter.name))"
    }

    func generateEffectInit(_ parameter: FunctionParameter) -> String
    {
        return "\(parameter.name): \(parameter.name)"
    }
}
