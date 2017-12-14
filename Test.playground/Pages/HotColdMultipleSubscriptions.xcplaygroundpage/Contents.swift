import RxSwift
import RxCocoa

playgroundShouldContinueIndefinitely()

// https://gist.github.com/inamiy/31bd4c3480f9a4a6c2e945c211c7fed0
do {
    let pub = PublishSubject<Int>()

    let o = pub.asDriver(onErrorJustReturn: -1)
        .map { x -> Int in
            print("map \(x)")
            return x
        }

    print("--- 1 ---")
    o.drive(onNext: { print("[sink1]", $0) })
    print("--- 2 ---")
    pub.onNext(1)
    print("--- 3 ---")
    o.drive(onNext: { print("[sink2]", $0) })
    print("--- 4 ---")
    pub.onNext(2)
}
