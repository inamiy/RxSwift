import RxSwift
import RxCocoa

playgroundShouldContinueIndefinitely()

/// `share()` is not `publish().refCount()`
/// - SeeAlso: https://github.com/ReactiveX/RxSwift/pull/1527
do {
    let o = Observable.of(1, 2) // finite cold
        .map { x -> Int in
            print("[map]", x)
            return x
        }
        .share(replay:0, scope: .whileConnected)

    print("--- 1 ---")
    o.subscribe(onNext: { print("[sink1]", $0) })
    print("--- 2 ---")
    o.subscribe(onNext: { print("[sink2]", $0) })

    //    --- 1 ---
    //    [map] 1
    //    [sink1] 1
    //    [map] 2
    //    [sink1] 2
    //    --- 2 ---
    //    [map] 1
    //    [sink2] 1
    //    [map] 2
    //    [sink2] 2
}

//--------------------------------------------------------------------------------

/// Time in milliseconds.
struct Timing {
    let onNextTime: Int
    let onCompletedTime: Int
    let subscriptionTimes: [Int]

    /// sub1 -> next -> completed -> sub2
    static let sub1NextCompletedSub2 = Timing(onNextTime: 100, onCompletedTime: 200, subscriptionTimes: [0, 300])

    /// sub1 -> next -> sub2 -> completed
    static let sub1NextSub2Completed = Timing(onNextTime: 100, onCompletedTime: 300, subscriptionTimes: [0, 200])

    /// sub1 -> sub2 -> next -> completed
    static let sub1Sub2NextCompleted = Timing(onNextTime: 200, onCompletedTime: 300, subscriptionTimes: [0, 100])
}

func runTest(timing: Timing, transform: (Observable<String>) -> Observable<String>) {
    func toSeconds(_ milliseconds: Int) -> TimeInterval {
        return TimeInterval(milliseconds) / 1e3
    }

    let o1 = Observable<String>.create { observer in
        print("start")
        delay(toSeconds(timing.onNextTime)) {
            let now = Date().timeIntervalSince1970.description
            observer.onNext(now)
        }
        delay(toSeconds(timing.onCompletedTime)) {
            observer.onCompleted()
        }
        return Disposables.create()
    }

    let o2: Observable<String> = transform(o1)

    for (i, sub) in timing.subscriptionTimes.enumerated() {
        delay(toSeconds(sub)) {
            print("--- \(i + 1) ---")
            o2.subscribe(onNext: { print("[sub \(i + 1)]", $0) })
        }
    }
}

// share(replay: 0, scope: .whileConnected)
xdo {
    let transform: (Observable<String>) -> Observable<String> = {
        $0.share(replay: 0, scope: .whileConnected)
    }

    // sub1 -> next -> completed -> sub2
    do {
        runTest(timing: .sub1NextCompletedSub2, transform: transform)
        //    --- 1 ---
        //    start
        //    [sub 1] 1513253706.93361
        //    --- 2 ---
        //    start
        //    [sub 2] 1513253707.24391 (not shared)
    }

    // sub1 -> next -> sub2 -> completed
    do {
        runTest(timing: .sub1NextSub2Completed, transform: transform)
        //    --- 1 ---
        //    start
        //    [sub 1] 1513253179.17745
        //    --- 2 ---
        //    (not shared)
    }

    // sub1 -> sub2 -> next -> completed
    do {
        runTest(timing: .sub1Sub2NextCompleted, transform: transform)
        //    --- 1 ---
        //    start
        //    --- 2 ---
        //    [sub 1] 1513253605.26019
        //    [sub 2] 1513253605.26019 (live-shared)
    }
}

// share(replay: 1, scope: .whileConnected)
xdo {
    let transform: (Observable<String>) -> Observable<String> = {
        $0.share(replay: 1, scope: .whileConnected)
    }

    // sub1 -> next -> completed -> sub2
    do {
        runTest(timing: .sub1NextCompletedSub2, transform: transform)
        //    --- 1 ---
        //    start
        //    [sub 1] 1513256304.08116
        //    --- 2 ---
        //    start
        //    [sub 2] 1513256304.40548 (not shared)
    }

    // sub1 -> next -> sub2 -> completed
    do {
        runTest(timing: .sub1NextSub2Completed, transform: transform)
        //    --- 1 ---
        //    start
        //    [sub 1] 1513256346.98911
        //    --- 2 ---
        //    [sub 2] 1513256346.98911 (cache-shared)
    }

    // sub1 -> sub2 -> next -> completed
    do {
        runTest(timing: .sub1Sub2NextCompleted, transform: transform)
        //    --- 1 ---
        //    start
        //    --- 2 ---
        //    [sub 1] 1513256536.85159
        //    [sub 2] 1513256536.85159 (live-shared)
    }
}

// share(replay: 0, scope: .forever)
xdo {
    let transform: (Observable<String>) -> Observable<String> = {
        $0.share(replay: 0, scope: .forever)
    }

    // sub1 -> next -> completed -> sub2
    do {
        runTest(timing: .sub1NextCompletedSub2, transform: transform)
        //    --- 1 ---
        //    start
        //    [sub 1] 1513256635.08104
        //    --- 2 ---
        //    (not shared)
    }

    // sub1 -> next -> sub2 -> completed
    do {
        runTest(timing: .sub1NextSub2Completed, transform: transform)
        //    --- 1 ---
        //    start
        //    [sub 1] 1513256655.27437
        //    --- 2 ---
        //    (not shared)
    }

    // sub1 -> sub2 -> next -> completed
    do {
        runTest(timing: .sub1Sub2NextCompleted, transform: transform)
        //    --- 1 ---
        //    start
        //    --- 2 ---
        //    [sub 1] 1513256682.67447
        //    [sub 2] 1513256682.67447 (live-shared)
    }
}

// share(replay: 1, scope: .forever)
xdo {
    let transform: (Observable<String>) -> Observable<String> = {
        $0.share(replay: 1, scope: .forever)
    }

    // sub1 -> next -> completed -> sub2
    do {
        runTest(timing: .sub1NextCompletedSub2, transform: transform)
        //    --- 1 ---
        //    start
        //    [sub 1] 1513256819.83083
        //    --- 2 ---
        //    [sub 2] 1513256819.83083 (cache-shared)
    }

    // sub1 -> next -> sub2 -> completed
    do {
        runTest(timing: .sub1NextSub2Completed, transform: transform)
        //    --- 1 ---
        //    start
        //    [sub 1] 1513256897.01234
        //    --- 2 ---
        //    [sub 2] 1513256897.01234 (cache-shared)
    }

    // sub1 -> sub2 -> next -> completed
    do {
        runTest(timing: .sub1Sub2NextCompleted, transform: transform)
        //    --- 1 ---
        //    start
        //    --- 2 ---
        //    [sub 1] 1513256920.28518
        //    [sub 2] 1513256920.28518 (live-shared)
    }
}

"done"
