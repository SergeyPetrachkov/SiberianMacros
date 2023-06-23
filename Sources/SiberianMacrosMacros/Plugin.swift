//
//  SiberianMacrosPlugin.swift
//
//
//  Created by Sergey Petrachkov on 15.06.2023.
//

import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct SiberianMacrosPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        PublicMemberwiseInit.self,
        CustomCodable.self,
        AutoMockable.self,
    ]
}
