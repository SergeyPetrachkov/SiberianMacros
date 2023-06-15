//
//  File.swift
//  
//
//  Created by Sergey Petrachkov on 15.06.2023.
//

import Foundation
import SwiftSyntax

enum ClassDeclarationGenerator {
    static func generate(
        className: TokenSyntax,
        protocolName: TokenSyntax
    ) -> ClassDeclSyntax {
        return ClassDeclSyntax(
            identifier: className,
            inheritanceClause: TypeInheritanceClauseSyntax {
                InheritedTypeSyntax(
                    typeName: SimpleTypeIdentifierSyntax(name: protocolName)
                )
            },
            memberBlockBuilder: {

            }
        )
    }
}
