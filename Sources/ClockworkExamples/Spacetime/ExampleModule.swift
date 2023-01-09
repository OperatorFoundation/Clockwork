//
//  ExampleModule.swift
//
//
//  Created by Clockwork on Jan 8, 2023.
//

import Foundation
#if os(macOS) || os(iOS)
import os.log
#else
import Logging
#endif

import Chord
import Simulation
import Spacetime

public class ExampleModule: Module
{
    static public let name = "Example"

    public var logger: Logger?

    let handler: Example

    public init(handler: Example)
    {
        self.handler = handler
    }

    public func name() -> String
    {
        return Self.name
    }

    public func setLogger(logger: Logger?)
    {
        self.logger = logger
    }

    public func handleEffect(_ effect: Effect, _ channel: BlockingQueue<Event>) -> Event?
    {
        switch effect
        {
            case let request as ExampleIncrementRequest:
                self.handler.increment()
                let response = ExampleIncrementResponse(request.id)
                print(response.description)
                return response
            case let request as ExampleAddRequest:
                self.handler.add(addition: request.addition)
                let response = ExampleAddResponse(request.id)
                print(response.description)
                return response
            case let request as ExamplePingRequest:
                let result = self.handler.ping()
                let response = ExamplePingResponse(request.id, result)
                print(response.description)
                return response
            case let request as ExampleTimesRequest:
                let result = self.handler.times(x: request.x)
                let response = ExampleTimesResponse(request.id, result)
                print(response.description)
                return response

            default:
                let response = Failure(effect.id)
                print(response.description)
                return response
        }
    }

    public func handleExternalEvent(_ event: Event)
    {
        return
    }
}