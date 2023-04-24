//
//  ArduinoLibraryFileList.swift
//  
//
//  Created by Dr. Brandon Wiley on 4/17/23.
//

import Foundation

import Gardener
import Text

public class ArduinoLibraryFileList
{
    public init()
    {
    }

    public func makeList(directory: URL) throws -> [URL]
    {
        let libraryName = directory.lastPathComponent
        let filenamePath = directory.appendingPathComponent("\(libraryName).h")
        let contents = try String(contentsOf: filenamePath)
        let text = Text(fromUTF8String: contents)

        let parts = text.split("\n")
        let lines = parts.filter
        {
            line in

            return line.containsSubstring("#include \"")
        }

        let filenames: [Text] = lines.map
        {
            line in

            let rightOfOpenQuote = line.split("\"")[1]
            return rightOfOpenQuote.split("\"")[0]
        }

        let filepaths: [URL] = filenames.map
        {
            filename in

            return directory.appending(component: filename, isDirectory: false)
        }

        let goodFilepaths: [URL] = filepaths.filter
        {
            url in

            return File.exists(url.path)
        }

        return goodFilepaths
    }
}
