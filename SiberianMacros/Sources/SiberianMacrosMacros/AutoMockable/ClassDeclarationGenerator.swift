//
//  File.swift
//  
//
//  Created by Sergey Petrachkov on 15.06.2023.
//

import SwiftSyntax

enum ClassDeclarationGenerator {
    static func generate(
        className: TokenSyntax,
        protocolName: TokenSyntax,
        variableDeclarations: [VariableDeclSyntax],
        functionDeclarations: [FunctionDeclSyntax]
    ) -> ClassDeclSyntax {
        return ClassDeclSyntax(
            identifier: className,
            inheritanceClause: TypeInheritanceClauseSyntax {
                InheritedTypeSyntax(
                    typeName: SimpleTypeIdentifierSyntax(name: protocolName)
                )
            },
            memberBlockBuilder: {
                for variableDeclaration in variableDeclarations {
                    // generate props
                }

                for functionDeclaration in functionDeclarations {
                    FunctionCallsCountGenerator.generate(funcDeclaration: functionDeclaration)
                }
            }
        )
    }
}
