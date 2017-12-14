import Dispatch
import PlaygroundSupport

public func playgroundShouldContinueIndefinitely() {
    PlaygroundPage.current.needsIndefiniteExecution = true
}

public func xdo(_ action: () -> Void) {
    // do nothing
}

public func delay(_ delay: Double, closure: @escaping () -> Void) {
    if delay > 0 {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: closure)
    } else {
        closure()
    }
}

