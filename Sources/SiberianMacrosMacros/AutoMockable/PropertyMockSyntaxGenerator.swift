//
//  PropertyMockSyntaxGenerator.swift
//
//
//  Created by Sergey Petrachkov on 23.06.2023.
//

import SwiftSyntax
import SwiftSyntaxBuilder

struct PropertyMockSyntaxGenerator {

    private class AccessorRemovalRewriter: SyntaxRewriter {
        override func visit(_ node: PatternBindingSyntax) -> PatternBindingSyntax {
            let superResult = super.visit(node)
            return superResult.with(\.accessor, nil)
        }
    }

    private let variableDecl: VariableDeclSyntax
    private let accessorRemovalRewriter: AccessorRemovalRewriter

    init(variableDecl: VariableDeclSyntax) {
        self.variableDecl = variableDecl
        self.accessorRemovalRewriter = AccessorRemovalRewriter()
    }

    @MemberDeclListBuilder
    func variablesDeclarations() -> MemberDeclListSyntax {
        if let binding = variableDecl.bindings.first {
            if let variableType = binding.typeAnnotation?.type, variableType.is(OptionalTypeSyntax.self) {
                accessorRemovalRewriter.visit(variableDecl)
            } else {
                protocolPropImplementationDeclaration(binding)
                underlyingPropDeclaration(binding)
            }
        }
    }

    private func protocolPropImplementationDeclaration(_ binding: PatternBindingListSyntax.Element) -> VariableDeclSyntax {
        let underlyingProperty = underlyingPropName(binding)
        let accessors = binding.accessor?.as(AccessorBlockSyntax.self)

        let accessorElements: [AccessorListSyntax.Element] = accessors?.accessors.count == 2 // FIXME: not completely right
        ? ["get { \(raw: underlyingProperty) }", "set { \(raw: underlyingProperty) = newValue }"]
        : ["get { \(raw: underlyingProperty) }"]

        return VariableDeclSyntax(
            bindingKeyword: .keyword(.var),
            bindingsBuilder: {
                PatternBindingSyntax(
                    pattern: binding.pattern,
                    typeAnnotation: binding.typeAnnotation,
                    accessor: .accessors(AccessorBlockSyntax(accessors: AccessorListSyntax(accessorElements)))
                )
            }
        )
    }

    private func underlyingPropDeclaration(_ binding: PatternBindingListSyntax.Element) -> VariableDeclSyntax {
        VariableDeclSyntax(
            bindingKeyword: .keyword(.var),
            bindingsBuilder: {
                PatternBindingSyntax(
                    pattern: IdentifierPatternSyntax(
                        identifier: .identifier(underlyingPropName(binding))
                    ),
                    typeAnnotation: TypeAnnotationSyntax(
                        type: ImplicitlyUnwrappedOptionalTypeSyntax(
                            wrappedType: TupleTypeSyntax(
                                elements: TupleTypeElementListSyntax {
                                    if let type = binding.typeAnnotation?.type {
                                        TupleTypeElementSyntax(type: type)
                                    }
                                }
                            )
                        )
                    )
                )
            }
        )
    }

    private func underlyingPropName(_ binding: PatternBindingListSyntax.Element) -> String {
        guard let identifierPattern = binding.pattern.as(IdentifierPatternSyntax.self) else {
            return ""
        }
        let identifierText = identifierPattern.identifier.text

        return "__\(identifierText)"
    }
}
