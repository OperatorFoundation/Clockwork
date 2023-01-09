//
//  ExampleMessages.swift
//
//
//  Created by Clockwork on Jan 8, 2023.
//

public enum ExampleRequest: Codable
{
    case increment
    case add(Add)
    case ping
    case times(Times)
}

public struct Add: Codable
{
    let addition: Int

    public init(addition: Int)
    {
        self.addition = addition
    }
}

public struct Times: Codable
{
    let x: Int

    public init(x: Int)
    {
        self.x = x
    }
}

public enum ExampleResponse: Codable
{
    case increment
    case add
    case ping(Pong)
    case times(Int)
}