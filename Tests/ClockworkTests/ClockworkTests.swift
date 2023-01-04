import XCTest

import Transmission

@testable import Clockwork

final class ClockworkTests: XCTestCase
{
    func testExample() throws
    {
        guard let listener = TransmissionListener(port: 5555, logger: nil) else
        {
            XCTFail()
            return
        }

        let example = Example()
        let server = ExampleServer(listener: listener, handler: example)
        print(server)

        guard let connection = TransmissionConnection(host: "127.0.0.1", port: 5555) else
        {
            XCTFail()
            return
        }

        let client = ExampleClient(connection: connection)

        try client.increment()

        try client.add(addition: 5)

        let pong = try client.ping()
        print(pong)

        let result = try client.times(x: 2)
        print(result)

        XCTAssertEqual(result, 12)
    }
}
