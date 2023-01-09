//
//  ExampleClient.swift
//
//
//  Created by Clockwork on Jan 8, 2023.
//

import Foundation

import TransmissionTypes

public class ExampleClient
{
    let connection: TransmissionTypes.Connection

    public init(connection: TransmissionTypes.Connection)
    {
        self.connection = connection
    }

    public func increment() throws
    {
        let message = ExampleRequest.increment
        let encoder = JSONEncoder()
        let data = try encoder.encode(message)
        guard self.connection.writeWithLengthPrefix(data: data, prefixSizeInBits: 64) else
        {
            throw ExampleClientError.writeFailed
        }

        guard let responseData = self.connection.readWithLengthPrefix(prefixSizeInBits: 64) else
        {
            throw ExampleClientError.readFailed
        }

        let decoder = JSONDecoder()
        let response = try decoder.decode(ExampleResponse.self, from: responseData)
        switch response
        {
            case .increment:
                return
            default:
                throw ExampleClientError.badReturnType
        }
    }

    public func add(addition: Int) throws
    {
        let message = ExampleRequest.add(Add(addition: addition))
        let encoder = JSONEncoder()
        let data = try encoder.encode(message)
        guard self.connection.writeWithLengthPrefix(data: data, prefixSizeInBits: 64) else
        {
            throw ExampleClientError.writeFailed
        }

        guard let responseData = self.connection.readWithLengthPrefix(prefixSizeInBits: 64) else
        {
            throw ExampleClientError.readFailed
        }

        let decoder = JSONDecoder()
        let response = try decoder.decode(ExampleResponse.self, from: responseData)
        switch response
        {
            case .add:
                return
            default:
                throw ExampleClientError.badReturnType
        }
    }

    public func ping() throws -> Pong
    {
        let message = ExampleRequest.ping
        let encoder = JSONEncoder()
        let data = try encoder.encode(message)
        guard self.connection.writeWithLengthPrefix(data: data, prefixSizeInBits: 64) else
        {
            throw ExampleClientError.writeFailed
        }

        guard let responseData = self.connection.readWithLengthPrefix(prefixSizeInBits: 64) else
        {
            throw ExampleClientError.readFailed
        }

        let decoder = JSONDecoder()
        let response = try decoder.decode(ExampleResponse.self, from: responseData)
        switch response
        {
            case .ping(let value):
                return value
            default:
                throw ExampleClientError.badReturnType
        }
    }

    public func times(x: Int) throws -> Int
    {
        let message = ExampleRequest.times(Times(x: x))
        let encoder = JSONEncoder()
        let data = try encoder.encode(message)
        guard self.connection.writeWithLengthPrefix(data: data, prefixSizeInBits: 64) else
        {
            throw ExampleClientError.writeFailed
        }

        guard let responseData = self.connection.readWithLengthPrefix(prefixSizeInBits: 64) else
        {
            throw ExampleClientError.readFailed
        }

        let decoder = JSONDecoder()
        let response = try decoder.decode(ExampleResponse.self, from: responseData)
        switch response
        {
            case .times(let value):
                return value
            default:
                throw ExampleClientError.badReturnType
        }
    }
}

public enum ExampleClientError: Error
{
    case connectionRefused(String, Int)
    case writeFailed
    case readFailed
    case badReturnType
}