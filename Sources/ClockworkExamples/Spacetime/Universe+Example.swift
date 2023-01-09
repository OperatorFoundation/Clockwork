//
//  Universe+Example.swift
//
//
//  Created by Clockwork on Jan 8, 2023.
//

import Foundation

import Spacetime
import Universe

extension Universe
{
    public func increment() throws
    {
        let request = ExampleIncrementRequest()
        let result = self.processEffect(request)

        switch result
        {
            case is ExampleIncrementResponse:
                return

            default:
                throw ExampleError.failure
        }
    }

    public func add(addition: Int) throws
    {
        let request = ExampleAddRequest(addition: addition)
        let result = self.processEffect(request)

        switch result
        {
            case is ExampleAddResponse:
                return

            default:
                throw ExampleError.failure
        }
    }

    public func ping() throws -> Pong
    {
        let request = ExamplePingRequest()
        let result = self.processEffect(request)

        switch result
        {
            case let response as ExamplePingResponse:
                return response.result

            default:
                throw ExampleError.failure
        }
    }

    public func times(x: Int) throws -> Int
    {
        let request = ExampleTimesRequest(x: x)
        let result = self.processEffect(request)

        switch result
        {
            case let response as ExampleTimesResponse:
                return response.result

            default:
                throw ExampleError.failure
        }
    }
}

public enum ExampleError: Error
{
    case failure
}