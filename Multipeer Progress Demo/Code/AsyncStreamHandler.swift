////    AsyncStreamCreator.swift
//
//
//    Created by Dan Galbraith on 8/12/24.
//
//    Copyright © 2024 Eidria Inc. All rights reserved.

import Foundation

public struct AsyncStreamHandler<Element: Sendable>: Sendable {
    public typealias Stream = AsyncStream<Element>
    public typealias Continuation = Stream.Continuation
    public typealias BufferingPolicy = Continuation.BufferingPolicy

    public private(set) var stream: Stream
    private var continuation: Continuation

    public init(bufferingPolicy: BufferingPolicy = .unbounded) {
        var tempContinuation: Stream.Continuation?
        stream = Stream(bufferingPolicy: bufferingPolicy) { continuation in
            tempContinuation = continuation
        }
        continuation = tempContinuation!
    }
    
    public func await(_ closure: @Sendable (Element) async -> Void) async {
        for await element in stream {
            await closure(element)
        }
    }

    public func add(_ element: Element) {
        continuation.yield(element)
    }

    public func finish() {
        continuation.finish()
    }
}
