//
//  ExampleServer.swift
//
//
//  Created by Clockwork on Jan 8, 2023.
//

import Foundation

import TransmissionTypes

public class ExampleServer
{
    let listener: TransmissionTypes.Listener
    let handler: Example

    var running: Bool = true

    public init(listener: TransmissionTypes.Listener, handler: Example)
    {
        self.listener = listener
        self.handler = handler

        Task
        {
            self.acceptLoop()
        }
    }

    public func shutdown()
    {
        self.running = false
    }

    func acceptLoop()
    {
        while self.running
        {
            do
            {
                let connection = try self.listener.accept()

                Task
                {
                    self.handleConnection(connection)
                }
            }
            catch
            {
                print(error)
                self.running = false
                return
            }
        }
    }

    func handleConnection(_ connection: TransmissionTypes.Connection)
    {
        while self.running
        {
            do
            {
                guard let requestData = connection.readWithLengthPrefix(prefixSizeInBits: 64) else
                {
                    throw ExampleServerError.readFailed
                }

                let decoder = JSONDecoder()
                let request = try decoder.decode(ExampleRequest.self, from: requestData)
                switch request
                {
                    case .increment:
                        self.handler.increment()
                        let response = ExampleResponse.increment
                        let encoder = JSONEncoder()
                        let responseData = try encoder.encode(response)
                        guard connection.writeWithLengthPrefix(data: responseData, prefixSizeInBits: 64) else
                        {
                            throw ExampleServerError.writeFailed
                        }
                    case .add(let value):
                        self.handler.add(addition: value.addition)
                        let response = ExampleResponse.add
                        let encoder = JSONEncoder()
                        let responseData = try encoder.encode(response)
                        guard connection.writeWithLengthPrefix(data: responseData, prefixSizeInBits: 64) else
                        {
                            throw ExampleServerError.writeFailed
                        }
                    case .ping:
                        let result = self.handler.ping()
                        let response = ExampleResponse.ping(result)
                        let encoder = JSONEncoder()
                        let responseData = try encoder.encode(response)
                        guard connection.writeWithLengthPrefix(data: responseData, prefixSizeInBits: 64) else
                        {
                            throw ExampleServerError.writeFailed
                        }
                    case .times(let value):
                        let result = self.handler.times(x: value.x)
                        let response = ExampleResponse.times(result)
                        let encoder = JSONEncoder()
                        let responseData = try encoder.encode(response)
                        guard connection.writeWithLengthPrefix(data: responseData, prefixSizeInBits: 64) else
                        {
                            throw ExampleServerError.writeFailed
                        }
                }
            }
            catch
            {
                print(error)
                return
            }
        }
    }
}

public enum ExampleServerError: Error
{
    case connectionRefused(String, Int)
    case writeFailed
    case readFailed
    case badReturnType
}