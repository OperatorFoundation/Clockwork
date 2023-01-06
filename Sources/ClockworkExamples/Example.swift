//
//  Example.swift
//  
//
//  Created by Dr. Brandon Wiley on 1/2/23.
//

import Foundation

import TransmissionTypes

public class Example
{
    var count = 0

    public func increment()
    {
        self.count = self.count + 1
    }

    public func add(addition: Int)
    {
        self.count = self.count + addition
    }

    public func ping() -> Pong
    {
        return Pong()
    }

    public func times(x: Int) -> Int
    {
        return self.count * x
    }
}

public struct Pong: Codable
{
    public init()
    {
    }
}
