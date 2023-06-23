import SiberianMacros

@AutoMockable
protocol SomeProtocol {
    var someProperty: Int { get set }
    var anotherOptionalProp: Bool? { get set }
    var readonlyProp: Double { get }

    func someMethod()
    func someMethodWithReturnValue() -> Bool
    func someMethodWith(argument: Int, anotherOne: Double) -> Bool
}

@CustomCodable
struct MyOperationOveriview: Codable {

    let id: Int

    let title: String?

    let description: String?

    @CodableKey(name: "auxiliary_info_by_user")
    var note: String?
}
