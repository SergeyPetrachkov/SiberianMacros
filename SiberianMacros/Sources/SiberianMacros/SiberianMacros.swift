@attached(member, names: named(`init`))
public macro PublicMemberwiseInit() = #externalMacro(
    module: "SiberianMacrosMacros",
    type: "PublicMemberwiseInit"
)

@attached(member, names: named(CodingKeys))
public macro CustomCodable() = #externalMacro(
    module: "SiberianMacrosMacros",
    type: "CustomCodable"
)

@attached(member)
public macro CodableKey(name: String) = #externalMacro(
    module: "SiberianMacrosMacros",
    type: "CodableKey"
)

@attached(peer, names: arbitrary)
public macro AutoMockable() -> () = #externalMacro(
    module: "SiberianMacrosMacros",
    type: "AutoMockable"
)
