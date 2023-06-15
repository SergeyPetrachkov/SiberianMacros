import SiberianMacros

@AutoMockable
protocol SomeProtocol {
    var someProperty: Int { get set }

    func someMethod()
    func someMethodWithReturnValue() -> Bool
    func someMethodWith(args: Int...) -> Bool
}
