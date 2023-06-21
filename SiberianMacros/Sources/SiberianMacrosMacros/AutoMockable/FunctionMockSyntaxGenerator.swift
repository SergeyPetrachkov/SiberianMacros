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
    private let functionName: String

    private let callsCountPropNameToken: TokenSyntax

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
        let type = Self.receivedArgsType(name: functionName, parametersList: parametersList)
        let identifier = Self.receivedArgsIdentifier(name: functionName, parametersList: parametersList)

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
        FunctionDeclSyntax(
            attributes: funcDeclaration.attributes,
            modifiers: funcDeclaration.modifiers,
            funcKeyword: funcDeclaration.funcKeyword,
            identifier: funcDeclaration.identifier,
            genericParameterClause: funcDeclaration.genericParameterClause,
            signature: funcDeclaration.signature,
            genericWhereClause: funcDeclaration.genericWhereClause,
            bodyBuilder: {
                let parametersList = funcDeclaration.signature.input.parameterList

                incrementVariableExpression(variablePrefix: functionName)

                if !parametersList.isEmpty {
                    let receivedArgsTypeIdentifier = Self.receivedArgsIdentifier(name: functionName, parametersList: parametersList)

                    SequenceExprSyntax {
                        IdentifierExprSyntax(identifier: receivedArgsTypeIdentifier)
                        AssignmentExprSyntax()
                        TupleExprSyntax {
                            for parameter in parametersList {
                                TupleExprElementSyntax(
                                    expression: IdentifierExprSyntax(
                                        identifier: parameter.secondName ?? parameter.firstName
                                    )
                                )
                            }
                        }
                    }

                    appendValueToVariableExpression(variablePrefix: functionName, parametersList: parametersList)
                }

                if funcDeclaration.signature.output == nil {
                    callExpression(
                        variablePrefix: functionName,
                        functionSignature: funcDeclaration.signature
                    )
                } else {
                    IfExprSyntax(
                        conditions: ConditionElementListSyntax {
                            ConditionElementSyntax(
                                condition: .expression(
                                    ExprSyntax(
                                        SequenceExprSyntax {
                                            IdentifierExprSyntax(identifier: .identifier(functionName + "Closure"))
                                            BinaryOperatorExprSyntax(operatorToken: .binaryOperator("!="))
                                            NilLiteralExprSyntax()
                                        }
                                    )
                                )
                            )
                        },
                        elseKeyword: .keyword(.else),
                        elseBody: .codeBlock(
                            CodeBlockSyntax {
                                ReturnStmtSyntax(
                                    returnKeyword: .keyword(.return),
                                    expression: IdentifierExprSyntax(
                                        identifier: TokenSyntax.identifier("\(functionName)ReturnValue")
                                    )
                                )
                            }
                        ),
                        bodyBuilder: {
                            let returnExpression = {
                                let calledExpression: ExprSyntaxProtocol

                                if funcDeclaration.signature.output == nil {
                                    calledExpression = OptionalChainingExprSyntax(
                                        expression: IdentifierExprSyntax(
                                            identifier: .identifier(functionName + "Closure")
                                        )
                                    )
                                } else {
                                    calledExpression = ForcedValueExprSyntax(
                                        expression: IdentifierExprSyntax(
                                            identifier: .identifier(functionName + "Closure")
                                        )
                                    )
                                }

                                var expression: ExprSyntaxProtocol = FunctionCallExprSyntax(
                                    calledExpression: calledExpression,
                                    leftParen: .leftParenToken(),
                                    argumentList: TupleExprElementListSyntax {
                                        for parameter in funcDeclaration.signature.input.parameterList {
                                            TupleExprElementSyntax(
                                                expression: IdentifierExprSyntax(
                                                    identifier: parameter.secondName ?? parameter.firstName
                                                )
                                            )
                                        }
                                    },
                                    rightParen: .rightParenToken()
                                )

                                if funcDeclaration.signature.effectSpecifiers?.asyncSpecifier != nil {
                                    expression = AwaitExprSyntax(expression: expression)
                                }

                                if funcDeclaration.signature.effectSpecifiers?.throwsSpecifier != nil {
                                    expression = TryExprSyntax(expression: expression)
                                }

                                return expression
                            }()
                            ReturnStmtSyntax(
                                expression: returnExpression
                            )
                        }
                    )
                }
            }
        )
    }

    func callExpression(variablePrefix: String, functionSignature: FunctionSignatureSyntax) -> ExprSyntaxProtocol {

        func variableIdentifier(variablePrefix: String) -> TokenSyntax {
            TokenSyntax.identifier(variablePrefix + "Closure")
        }

        let calledExpression: ExprSyntaxProtocol

        if functionSignature.output == nil {
            calledExpression = OptionalChainingExprSyntax(
                expression: IdentifierExprSyntax(
                    identifier: variableIdentifier(variablePrefix: variablePrefix)
                )
            )
        } else {
            calledExpression = ForcedValueExprSyntax(
                expression: IdentifierExprSyntax(
                    identifier: variableIdentifier(variablePrefix: variablePrefix)
                )
            )
        }

        var expression: ExprSyntaxProtocol = FunctionCallExprSyntax(
            calledExpression: calledExpression,
            leftParen: .leftParenToken(),
            argumentList: TupleExprElementListSyntax {
                for parameter in functionSignature.input.parameterList {
                    TupleExprElementSyntax(
                        expression: IdentifierExprSyntax(
                            identifier: parameter.secondName ?? parameter.firstName
                        )
                    )
                }
            },
            rightParen: .rightParenToken()
        )

        if functionSignature.effectSpecifiers?.asyncSpecifier != nil {
            expression = AwaitExprSyntax(expression: expression)
        }

        if functionSignature.effectSpecifiers?.throwsSpecifier != nil {
            expression = TryExprSyntax(expression: expression)
        }

        return expression
    }

    func incrementVariableExpression(variablePrefix: String) -> SequenceExprSyntax {
        func variableIdentifier(variablePrefix: String) -> TokenSyntax {
            TokenSyntax.identifier(variablePrefix + "CallsCount")
        }

        return SequenceExprSyntax {
            IdentifierExprSyntax(identifier: variableIdentifier(variablePrefix: variablePrefix))
            BinaryOperatorExprSyntax(operatorToken: .binaryOperator("+="))
            IntegerLiteralExprSyntax(digits: .integerLiteral("1"))
        }
    }

    static func expandedFuncName(funcDeclaration: FunctionDeclSyntax) -> String {
        var parts: [String] = [funcDeclaration.identifier.text]

        let parameterList = funcDeclaration.signature.input.parameterList

        let parameters = parameterList
            .map { $0.firstName.text }
            .filter { $0 != "_" }
            .map { $0.capitalized }

        parts.append(contentsOf: parameters)

        return parts.joined()
    }

    static func receivedArgsType(name: String, parametersList: FunctionParameterListSyntax) -> TypeSyntaxProtocol {
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
    }

    private static func receivedArgsIdentifier(name: String, parametersList: FunctionParameterListSyntax) -> TokenSyntax {
        if parametersList.count == 1, let onlyParameter = parametersList.first {
            let parameterNameToken = onlyParameter.secondName ?? onlyParameter.firstName
            let parameterNameText = parameterNameToken.text
            let capitalizedParameterName = parameterNameText.prefix(1).uppercased() + parameterNameText.dropFirst()

            return .identifier(name + "Received" + capitalizedParameterName)
        } else {
            return .identifier(name + "ReceivedArguments")
        }
    }


    func appendValueToVariableExpression(variablePrefix: String, parametersList: FunctionParameterListSyntax) -> FunctionCallExprSyntax {
        let identifier = Self.receivedInfocationsIdentifier(name: variablePrefix)
        let calledExpression = MemberAccessExprSyntax(
            base: IdentifierExprSyntax(identifier: identifier),
            dot: .periodToken(),
            name: .identifier("append")
        )
        let argument = appendArgumentExpression(parametersList: parametersList)

        return FunctionCallExprSyntax(
            calledExpression: calledExpression,
            leftParen: .leftParenToken(),
            argumentList: argument,
            rightParen: .rightParenToken()
        )
    }

    private func appendArgumentExpression(parametersList: FunctionParameterListSyntax) -> TupleExprElementListSyntax {
        let tupleArgument = TupleExprSyntax(
            elementListBuilder: {
                for parameter in parametersList {
                    TupleExprElementSyntax(
                        expression: IdentifierExprSyntax(
                            identifier: parameter.secondName ?? parameter.firstName
                        )
                    )
                }
            }
        )

        return TupleExprElementListSyntax {
            TupleExprElementSyntax(expression: tupleArgument)
        }
    }

    static func receivedInfocationsIdentifier(name: String) -> TokenSyntax {
        TokenSyntax.identifier(name + "ReceivedInvocations")
    }
}
