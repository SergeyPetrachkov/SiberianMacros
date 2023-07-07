import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics

public struct PublicMemberwiseInit: MemberMacro {

    enum Errors: String, DiagnosticMessage, Error {
        case invalidInputType

        var message: String {
            "@PublicMemberwiseInit is only applicable to structs or classes"
        }

        var diagnosticID: MessageID {
            MessageID(domain: "PublicMemberwiseInit", id: rawValue)
        }

        var severity: DiagnosticSeverity {
            .error
        }
    }

    public static func expansion(
        of attribute: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {

        let storedProperties: [VariableDeclSyntax] = try {
            if let classDeclaration = declaration.as(ClassDeclSyntax.self) {
                return classDeclaration.storedProperties()
            } else if let structDeclaration = declaration.as(StructDeclSyntax.self) {
                return structDeclaration.storedProperties()
            } else {
                throw Errors.invalidInputType
            }
        }()

        let initArguments = storedProperties.compactMap { property -> (name: String, type: String)? in
            guard let patternBinding = property.bindings.first?.as(PatternBindingSyntax.self) else {
                return nil
            }

            guard let name = patternBinding.pattern.as(IdentifierPatternSyntax.self)?.identifier,
                  let type = patternBinding.typeAnnotation?.as(TypeAnnotationSyntax.self)?.type.as(SimpleTypeIdentifierSyntax.self)?.name else {
                return nil
            }

            return (name: name.text, type: type.text)
        }

        let initBody: ExprSyntax = "\(raw: initArguments.map { "self.\($0.name) = \($0.name)" }.joined(separator: "\n"))"

        let initDeclSyntax = try InitializerDeclSyntax(
            PartialSyntaxNodeString(stringLiteral: "public init(\(initArguments.map { "\($0.name): \($0.type)" }.joined(separator: ", ")))"),
            bodyBuilder: {
                initBody
            }
        )

        let finalDeclaration = DeclSyntax(initDeclSyntax)

        return [finalDeclaration]
    }
}
