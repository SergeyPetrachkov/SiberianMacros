//
//  CustomCodable.swift
//  
//
//  Created by Sergey Petrachkov on 15.06.2023.
//

import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct CodableKey: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        // Does nothing, used only to decorate members with data
        return []
    }
}

public struct CustomCodable: MemberMacro {

    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {

        let memberList = declaration.memberBlock.members

        let cases = memberList.compactMap { member -> String? in
            guard let propertyName = member.decl.as(VariableDeclSyntax.self)?.propertyName else {
                return nil
            }

            let customKeyMacroAttribute = member
                .decl
                .as(VariableDeclSyntax.self)?
                .attributes?
                .first(
                    where: {
                        $0
                            .as(AttributeSyntax.self)?
                            .attributeName
                            .as(SimpleTypeIdentifierSyntax.self)?
                            .description == "CodableKey"
                    }
                )?
                .as(AttributeSyntax.self)

            let customKeyValue = customKeyMacroAttribute?
                .argument?
                .as(TupleExprElementListSyntax.self)?
                .first?
                .expression

            guard let customKeyValue = customKeyValue else {
                return "case \(propertyName)"
            }

            return "case \(propertyName) = \(customKeyValue)"
        }

        let codingKeys: DeclSyntax =
        """

        enum CodingKeys: String, CodingKey {
            \(raw: cases.joined(separator: "\n"))
        }

        """

        return [
            codingKeys
        ]
    }
}
