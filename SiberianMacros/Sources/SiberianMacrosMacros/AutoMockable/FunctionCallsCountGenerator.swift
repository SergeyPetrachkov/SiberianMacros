//
//  FunctionCallsCountGenerator.swift
//  
//
//  Created by Sergey Petrachkov on 15.06.2023.
//

import SwiftSyntax

enum FunctionCallsCountGenerator {

    static func generate(funcDeclaration: FunctionDeclSyntax) -> VariableDeclSyntax {
        let functionName = expandedFuncName(funcDeclaration: funcDeclaration)
        return VariableDeclSyntax(
            bindingKeyword: .keyword(.var),
            bindingsBuilder: {
                PatternBindingSyntax(
                    pattern: IdentifierPatternSyntax(
                        identifier: TokenSyntax.identifier("\(functionName)CallsCount")
                    ),
                    initializer: InitializerClauseSyntax(
                        value: IntegerLiteralExprSyntax(digits: .integerLiteral("0"))
                    )
                )
            }
        )
    }

    private static func expandedFuncName(funcDeclaration: FunctionDeclSyntax) -> String {
        var parts: [String] = [funcDeclaration.identifier.text]

        let parameterList = funcDeclaration.signature.input.parameterList

        let parameters = parameterList
            .map { $0.firstName.text }
            .filter { $0 != "_" }
            .map { $0.capitalized }

        parts.append(contentsOf: parameters)

        return parts.joined()
    }
}
