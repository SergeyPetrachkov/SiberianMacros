//
//  DeclGroupSyntax+.swift
//
//
//  Created by Sergey Petrachkov on 15.06.2023.
//

import Foundation
import SwiftSyntax
import SwiftSyntaxBuilder

extension DeclGroupSyntax {

    /// Get the stored properties from the declaration based on syntax.
    func storedProperties() -> [VariableDeclSyntax] {
        return memberBlock.members.compactMap { member in
            guard let variable = member.decl.as(VariableDeclSyntax.self),
                  variable.isStoredProperty else {
                return nil
            }

            return variable
        }
    }
}
