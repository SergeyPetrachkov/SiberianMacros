@attached(member, names: named(`init`))
public macro PublicMemberwiseInit() = #externalMacro(
    module: "MacrosImplementation",
    type: "PublicMemberwiseInit"
)

@attached(member, names: named(CodingKeys))
public macro CustomCodable() = #externalMacro(
    module: "MacrosImplementation",
    type: "CustomCodable"
)

@attached(member)
public macro CodableKey(name: String) = #externalMacro(
    module: "MacrosImplementation",
    type: "CodableKey"
)

@attached(peer, names: arbitrary)
public macro AutoMockable() = #externalMacro(
    module: "MacrosImplementation",
    type: "AutoMockable"
)
