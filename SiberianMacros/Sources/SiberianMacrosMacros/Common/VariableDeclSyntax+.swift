//
//  VariableDeclSyntax+.swift
//
//
//  Created by Sergey Petrachkov on 15.06.2023.
//

import Foundation
import SwiftSyntax
import SwiftSyntaxBuilder

extension VariableDeclSyntax {
    /// Check if this variable has the syntax of a stored property.
    var isStoredProperty: Bool {
        guard let binding = bindings.first,
              bindings.count == 1,
              !isLazyProperty,
              !isConstant else {
            return false
        }

        switch binding.accessor {
        case .none:
            return true
        case .accessors(let node):
            // traverse accessors
            for accessor in node.accessors {
                switch accessor.accessorKind.tokenKind {
                case .keyword(.willSet), .keyword(.didSet):
                    // stored properties can have observers
                    break
                default:
                    // everything else makes it a computed property
                    return false
                }
            }
            return true
        case .getter:
            return false
        }
    }

    var isLazyProperty: Bool {
        modifiers?.contains { $0.name.tokenKind == .keyword(Keyword.lazy) } ?? false
    }

    var isConstant: Bool {
        bindingKeyword.tokenKind == .keyword(Keyword.let) && bindings.first?.initializer != nil
    }

    var propertyName: String? {
        bindings.first?.pattern.as(IdentifierPatternSyntax.self)?.identifier.text
    }
}
