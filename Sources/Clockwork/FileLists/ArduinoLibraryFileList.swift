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

            return line.contains("#include") && line.contains("\"")
        }

        let includes: [URL] = lines.compactMap
        {
            line in

            let rightOfOpenQuote = line.split("\"")[1]
            let leftOfCloseQuote = rightOfOpenQuote.split("\"")[0]
            let filename = leftOfCloseQuote

            let includedFilePath = directory.appending(component: filename, isDirectory: false)
            guard File.exists(includedFilePath.path) else
            {
                return nil
            }

            return includedFilePath
        }

        return includes
    }
}
