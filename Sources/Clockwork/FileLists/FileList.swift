//
//  FileList.swift
//  
//
//  Created by Dr. Brandon Wiley on 4/17/23.
//

import Foundation

public protocol FileList
{
    func makeList(directory: URL) -> [URL]
}
