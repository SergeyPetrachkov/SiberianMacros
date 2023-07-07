//
//  String+.swift
//
//
//  Created by Sergey Petrachkov on 07.07.2023.
//

extension String {
    var firstLetterCapitalized: String {
        self.prefix(1).uppercased() + self.dropFirst()
    }
}
