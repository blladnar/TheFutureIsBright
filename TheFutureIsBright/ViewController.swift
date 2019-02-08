//
//  ViewController.swift
//  TheFutureIsBright
//
//  Created by RBrown on 2/8/19.
//  Copyright © 2019 RBrown. All rights reserved.
//

import UIKit
import BrightFutures
import Result

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func synchronous(_ sender: Any) {
        let startDate = Date()
        let value = getValue()
        let endDate = Date()
        print(value, endDate.timeIntervalSince1970 - startDate.timeIntervalSince1970)
    }

    @IBAction func asynchronous(_ sender: Any) {
        asyncWithCompletion { result in
            switch result {
            case .success(let value):
                print("Async Block", value)
            case .failure(_):
                break
            }
        }


        let future = await asyncGetValue()

        future.onSuccess { value in
            print("Async Future", value)
        }
    }

    @IBAction func map(_ sender: Any) {
        asyncGetValue(4)
            .map { value in
                return "X".padding(toLength: value, withPad: "X", startingAt: 0)
            }
            .onSuccess { stringValue in
                print(stringValue)
            }
    }

    @IBAction func sequence(_ sender: Any) {
        let startDate = Date()
        [asyncGetValue(1),
         asyncGetValue(2),
         asyncGetValue(3),
         asyncGetValue(4),
         asyncGetValue(5),
         asyncGetValue(6),
         asyncGetValue(7),
         asyncGetValue(8)].sequence().onSuccess { values in
            let endDate = Date()
            print(values, endDate.timeIntervalSince1970 - startDate.timeIntervalSince1970)
        }
    }

    @IBAction func mock(_ sender: Any) {
        let mockService = MockNetworkService()
        let promise = Promise<String, DemoError>()
        promise.complete(.success("Hello"))

        mockService.stubPromise = promise

        mockService.getValueFromInternet().onSuccess { value in
            print(value)
        }
    }

    @IBAction func filter(_ sender: Any) {
        asyncGetValue(3)
            .filter { $0 > 5 }
            .onSuccess { value in
                print("Filter", value)
            }
            .onFailure { error in
                print(error)
            }
    }


}

func getValue(_ value: Int = 42) -> Int {
    let sleepTime = UInt32.random(in: 1 ... 5)
    sleep(sleepTime)
    print(value)
    return value
}

func asyncGetValue(_ value: Int = 42) -> Future<Int, DemoError> {
    return Future { complete in
        DispatchQueue.global().async {
            complete(.success(getValue(value)))
        }
    }
}

func asyncWithCompletion(_ completion: @escaping (Result<Int, DemoError>) -> Void) {
    DispatchQueue.global().async {
        completion(.success(getValue()))
    }
}

enum DemoError : Error {
    case exampleError
    case networkError
}

protocol NetworkService {
    func getValueFromInternet() -> Future<String, DemoError>
}

class RealNetworkService : NetworkService {
    func getValueFromInternet() -> Future<String, DemoError> {
        return asyncGetValue().map { value in
            return "Internet \(value)"
        }
    }
}

class MockNetworkService : NetworkService {
    var stubPromise: Promise<String, DemoError>?
    func getValueFromInternet() -> Future<String, DemoError> {
        return stubPromise!.future
    }
}
