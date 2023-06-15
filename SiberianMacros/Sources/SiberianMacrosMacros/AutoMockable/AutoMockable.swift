//
//  AutoMockable.swift
//  
//
//  Created by Sergey Petrachkov on 15.06.2023.
//

import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics

public struct AutoMockable: PeerMacro {

    enum Errors: String, DiagnosticMessage, Error {
        case invalidInputType

        var message: String {
            "@AutoMockable is only applicable to protocols"
        }

        var diagnosticID: MessageID {
            MessageID(domain: "AutoMockable", id: rawValue)
        }

        var severity: DiagnosticSeverity {
            .error
        }
    }

    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let protocolDeclaration = declaration.as(ProtocolDeclSyntax.self) else {
            throw Errors.invalidInputType
        }

        let mockClassName = TokenSyntax.identifier("Mock\(protocolDeclaration.identifier.text)")

        let variableDeclarations = protocolDeclaration
            .memberBlock
            .members
            .compactMap { $0.decl.as(VariableDeclSyntax.self) }

        let functionDeclarations = protocolDeclaration
            .memberBlock
            .members
            .compactMap { $0.decl.as(FunctionDeclSyntax.self) }

        let mockClassDeclaration = ClassDeclarationGenerator.generate(
            className: mockClassName,
            protocolName: protocolDeclaration.identifier,
            variableDeclarations: variableDeclarations,
            functionDeclarations: functionDeclarations
        )
        return [DeclSyntax(mockClassDeclaration)]
    }
}
