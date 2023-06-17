//
//  File.swift
//  
//
//  Created by Sergey Petrachkov on 15.06.2023.
//

import SwiftSyntax
import SwiftSyntaxBuilder

enum ClassDeclarationGenerator {
    static func generate(
        className: TokenSyntax,
        protocolName: TokenSyntax,
        variableDeclarations: [VariableDeclSyntax],
        functionDeclarations: [FunctionDeclSyntax]
    ) throws -> ClassDeclSyntax {
        ClassDeclSyntax(
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
                    let generator = FunctionMockSyntaxGenerator(funcDeclaration: functionDeclaration)
                    generator.generateCallsCountProperty()
                    generator.generateCalledProperty()

                    if let returnValueProperty = generator.generateReturnValuePropertyIfNeeded() {
                        returnValueProperty
                    }

                    generator.generateClosure()
                }

//
//                if !parameterList.isEmpty {
//                    receivedArgumentsFactory.variableDeclaration(
//                        variablePrefix: variablePrefix,
//                        parameterList: parameterList
//                    )
//                    receivedInvocationsFactory.variableDeclaration(
//                        variablePrefix: variablePrefix,
//                        parameterList: parameterList
//                    )
//                }

//                functionImplementationFactory.declaration(
//                    variablePrefix: variablePrefix,
//                    protocolFunctionDeclaration: functionDeclaration
//                )
            }
        )
    }
}
