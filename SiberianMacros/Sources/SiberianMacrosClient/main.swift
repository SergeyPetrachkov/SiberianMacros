import SiberianMacros

@AutoMockable
protocol SomeProtocol {
//    var someProperty: Int { get set }

    func someMethod()
    func someMethodWithReturnValue() -> Bool
    func someMethodWith(argument: Int, anotherOne: Double) -> Bool
}
