//
//  FunctionCallsCountGenerator.swift
//  
//
//  Created by Sergey Petrachkov on 15.06.2023.
//

import SwiftSyntax
import SwiftSyntaxBuilder

struct FunctionMockSyntaxGenerator {

    private let funcDeclaration: FunctionDeclSyntax
    private let callsCountPropNameToken: TokenSyntax
    private let functionName: String

    init(funcDeclaration: FunctionDeclSyntax) {
        self.funcDeclaration = funcDeclaration
        self.functionName = Self.expandedFuncName(funcDeclaration: funcDeclaration)
        self.callsCountPropNameToken = TokenSyntax.identifier("\(functionName)CallsCount")
    }

    func generateCallsCountProperty() -> VariableDeclSyntax {
        VariableDeclSyntax(
                bindingKeyword: .keyword(.var),
                bindingsBuilder: {
                    PatternBindingSyntax(
                        pattern: IdentifierPatternSyntax(
                            identifier: callsCountPropNameToken
                        ),
                        initializer: InitializerClauseSyntax(
                            value: IntegerLiteralExprSyntax(digits: .integerLiteral("0"))
                        )
                    )
                }
            )
    }

    func generateCalledProperty() -> VariableDeclSyntax {
        VariableDeclSyntax(
            bindingKeyword: .keyword(.var),
            bindingsBuilder: {
                PatternBindingSyntax(
                    pattern: IdentifierPatternSyntax(
                        identifier: .identifier("\(functionName)Called")
                    ),
                    typeAnnotation: TypeAnnotationSyntax(
                        type: SimpleTypeIdentifierSyntax(name: .identifier("Bool"))
                    ),
                    accessor: .getter(
                        CodeBlockSyntax {
                            ReturnStmtSyntax(
                                expression: SequenceExprSyntax {
                                    IdentifierExprSyntax(
                                        identifier: callsCountPropNameToken
                                    )
                                    BinaryOperatorExprSyntax(
                                        operatorToken: .binaryOperator(">")
                                    )
                                    IntegerLiteralExprSyntax(
                                        digits: .integerLiteral("0")
                                    )
                                }
                            )
                        }
                    )
                )
            }
        )
    }

    func generateReturnValuePropertyIfNeeded() -> VariableDeclSyntax? {
        guard let returnType = funcDeclaration.signature.output?.returnType else {
            return nil
        }

        return VariableDeclSyntax(
            bindingKeyword: .keyword(.var),
            bindingsBuilder: {
                PatternBindingSyntax(
                    pattern: IdentifierPatternSyntax(
                        identifier: TokenSyntax.identifier("\(functionName)ReturnValue")
                    ),
                    typeAnnotation: {
                        if returnType.is(OptionalTypeSyntax.self) {
                            TypeAnnotationSyntax(type: returnType)
                        } else {
                            TypeAnnotationSyntax(
                                type: ImplicitlyUnwrappedOptionalTypeSyntax(wrappedType: returnType)
                            )
                        }
                    }()
                )
            }
        )
    }

    func generateReceivedArgsIfNeeded() -> VariableDeclSyntax? {
        let parametersList = funcDeclaration.signature.input.parameterList
        if parametersList.isEmpty {
            return nil
        }
        // FIXME: make this work with `Int...` like args
        let type: TypeSyntaxProtocol = {
            let variableType: TypeSyntaxProtocol

            if parametersList.count == 1, let onlyParameter = parametersList.first {
                if onlyParameter.type.is(OptionalTypeSyntax.self) {
                    variableType = onlyParameter.type
                } else {
                    variableType = OptionalTypeSyntax(wrappedType: onlyParameter.type, questionMark: .postfixQuestionMarkToken())
                }
            } else {
                let tupleElements = TupleTypeElementListSyntax {
                    for parameter in parametersList {
                        TupleTypeElementSyntax(
                            name: parameter.secondName ?? parameter.firstName,
                            colon: .colonToken(),
                            type: parameter.type
                        )
                    }
                }
                variableType = OptionalTypeSyntax(
                    wrappedType: TupleTypeSyntax(elements: tupleElements),
                    questionMark: .postfixQuestionMarkToken()
                )
            }

            return variableType
        }()

        let identifier: TokenSyntax = {
            if parametersList.count == 1, let onlyParameter = parametersList.first {
                let parameterNameToken = onlyParameter.secondName ?? onlyParameter.firstName
                let parameterNameText = parameterNameToken.text
                let capitalizedParameterName = parameterNameText.capitalized

                return .identifier(functionName + "Received" + capitalizedParameterName)
            } else {
                return .identifier(functionName + "ReceivedArguments")
            }
        }()

        return VariableDeclSyntax(
            bindingKeyword: .keyword(.var),
            bindingsBuilder: {
                PatternBindingSyntax(
                    pattern: IdentifierPatternSyntax(identifier: identifier),
                    typeAnnotation: TypeAnnotationSyntax(
                        type: type
                    )
                )
            }
        )
    }

    func generateReceivedInvocationsIfNeeded() -> VariableDeclSyntax? {
        let parametersList = funcDeclaration.signature.input.parameterList
        if parametersList.isEmpty {
            return nil
        }

        let identifier = TokenSyntax.identifier(functionName + "ReceivedInvocations")


        let elementType: TypeSyntaxProtocol = {
            let arrayElementType: TypeSyntaxProtocol

            if parametersList.count == 1, let onlyParameter = parametersList.first {
                arrayElementType = onlyParameter.type
            } else {
                let tupleElements = TupleTypeElementListSyntax {
                    for parameter in parametersList {
                        TupleTypeElementSyntax(
                            name: parameter.secondName ?? parameter.firstName,
                            colon: .colonToken(),
                            type: parameter.type
                        )
                    }
                }
                arrayElementType = TupleTypeSyntax(elements: tupleElements)
            }

            return arrayElementType
        }()

        return VariableDeclSyntax(
            bindingKeyword: .keyword(.var),
            bindingsBuilder: {
                PatternBindingSyntax(
                    pattern: IdentifierPatternSyntax(identifier: identifier),
                    typeAnnotation: TypeAnnotationSyntax(
                        type: ArrayTypeSyntax(elementType: elementType)
                    ),
                    initializer: InitializerClauseSyntax(
                        value: ArrayExprSyntax(elementsBuilder: {})
                    )
                )
            }
        )
    }

    func generateClosure() -> VariableDeclSyntax {
        let funcSignature = funcDeclaration.signature
        let elements = TupleTypeElementListSyntax {
            TupleTypeElementSyntax(
                type: FunctionTypeSyntax(
                    arguments: TupleTypeElementListSyntax {
                        for parameter in funcSignature.input.parameterList {
                            TupleTypeElementSyntax(type: parameter.type)
                        }
                    },
                    effectSpecifiers: TypeEffectSpecifiersSyntax(
                        asyncSpecifier: funcSignature.effectSpecifiers?.asyncSpecifier,
                        throwsSpecifier: funcSignature.effectSpecifiers?.throwsSpecifier
                    ),
                    output: funcSignature.output ?? ReturnClauseSyntax(
                        returnType: SimpleTypeIdentifierSyntax(
                            name: .identifier("Void")
                        )
                    )
                )
            )
        }

        let typeAnnotation = TypeAnnotationSyntax(
            type: OptionalTypeSyntax(
                wrappedType: TupleTypeSyntax(
                    elements: elements
                )
            )
        )

        return VariableDeclSyntax(
            bindingKeyword: .keyword(.var),
            bindingsBuilder: {
                PatternBindingSyntax(
                    pattern: IdentifierPatternSyntax(
                        identifier: TokenSyntax.identifier("\(functionName)Closure")
                    ),
                    typeAnnotation: typeAnnotation
                )
            }
        )
    }

    func generateFunctionImplementation() -> FunctionDeclSyntax {
        fatalError("Not implemented")
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
