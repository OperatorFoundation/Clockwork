//
//  String+CapitalizeFirstLetter.swift
//  
//
//  Created by Dr. Brandon Wiley on 1/12/23.
//

import Foundation

extension String
{
    func capitalizingFirstLetter() -> String
    {
        return prefix(1).uppercased() + self.lowercased().dropFirst()
    }

    mutating func capitalizeFirstLetter()
    {
        self = self.capitalizingFirstLetter()
    }
}
