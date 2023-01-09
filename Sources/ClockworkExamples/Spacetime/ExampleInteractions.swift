//
//  ExampleInteractions.swift
//
//
//  Created by ClockworkSpacetime on Jan 8, 2023.
//

import Foundation

import Spacetime

public class ExampleEffect: Effect
{
    enum CodingKeys: String, CodingKey
    {
        case id
    }

    public init()
    {
        super.init(module: "Example")
    }

    public init(id: UUID)
    {
        super.init(id: id, module: "Example")
    }

    public required init(from decoder: Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let id = try container.decode(UUID.self, forKey: .id)

        super.init(id: id, module: "Example")
    }
}

public class ExampleEvent: Event
{
    enum CodingKeys: String, CodingKey
    {
        case effectId
    }

    public init(_ effectId: UUID)
    {
        super.init(effectId, module: "Example")
    }

    public required init(from decoder: Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let effectId = try container.decode(UUID.self, forKey: .effectId)

        super.init(effectId, module: "Example")
    }
}

public class ExampleIncrementRequest: ExampleEffect
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

public class ExampleIncrementResponse: ExampleEvent
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

public class ExampleAddRequest: ExampleEffect
{
    let addition: Int

    enum CodingKeys: String, CodingKey
    {
        case id
        case addition
    }

    public init(addition: Int)
    {
        self.addition = addition

        super.init()
    }

    public init(id: UUID, addition: Int)
    {
        self.addition = addition

        super.init(id: id)
    }

    public required init(from decoder: Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let id = try container.decode(UUID.self, forKey: .id)
        let addition: Int = try container.decode(Int.self, forKey: .addition)

        self.addition = addition
        super.init(id: id)
    }
}

public class ExampleAddResponse: ExampleEvent
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

public class ExamplePingRequest: ExampleEffect
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

public class ExamplePingResponse: ExampleEvent
{
    let result: Pong

    enum CodingKeys: String, CodingKey
    {
        case effectId
        case result
    }

    public init(_ effectId: UUID, _ result: Pong)
    {
        self.result = result

        super.init(effectId)
    }

    public required init(from decoder: Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let effectId = try container.decode(UUID.self, forKey: .effectId)
        let result = try container.decode(Pong.self, forKey: .result)

        self.result = result
        super.init(effectId)
    }
}

public class ExampleTimesRequest: ExampleEffect
{
    let x: Int

    enum CodingKeys: String, CodingKey
    {
        case id
        case x
    }

    public init(x: Int)
    {
        self.x = x

        super.init()
    }

    public init(id: UUID, x: Int)
    {
        self.x = x

        super.init(id: id)
    }

    public required init(from decoder: Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let id = try container.decode(UUID.self, forKey: .id)
        let x: Int = try container.decode(Int.self, forKey: .x)

        self.x = x
        super.init(id: id)
    }
}

public class ExampleTimesResponse: ExampleEvent
{
    let result: Int

    enum CodingKeys: String, CodingKey
    {
        case effectId
        case result
    }

    public init(_ effectId: UUID, _ result: Int)
    {
        self.result = result

        super.init(effectId)
    }

    public required init(from decoder: Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let effectId = try container.decode(UUID.self, forKey: .effectId)
        let result = try container.decode(Int.self, forKey: .result)

        self.result = result
        super.init(effectId)
    }
}