// The MIT License (MIT)
//
// Copyright (c) 2020–2023 Alexander Grebenyuk (github.com/kean).

#if os(iOS) || os(macOS)

import Foundation
import Pulse
@preconcurrency import CoreData

/// Collects insights about the current session.
struct NetworkLoggerInsights {
    var transferSize = NetworkLogger.TransferSizeInfo()
    var duration = RequestsDurationInfo()
    var redirects = RedirectsInfo()
    var failures = FailuresInfo()

    init(_ tasks: [NetworkTaskEntity]) {
        for task in tasks {
            insert(task)
        }
    }

    mutating func insert(_ task: NetworkTaskEntity) {
        guard task.state != .pending else { return }

        transferSize = transferSize.merging(task.totalTransferSize)
        if let duration = task.taskInterval?.duration, duration > 0 {
            self.duration.insert(duration: duration, taskId: task.objectID)
        }
        if task.redirectCount > 0 {
            redirects.count += Int(task.redirectCount)
            redirects.taskIds.append(task.objectID)
            redirects.timeLost += task.transactions
                .filter({ $0.response?.statusCode == 302 })
                .map { $0.timing.duration ?? 0 }
                .reduce(0, +)
        }
        if task.state == .failure {
            failures.taskIds.append(task.objectID)
        }
    }

    struct RequestsDurationInfo: Sendable {
        var median: TimeInterval?
        var maximum: TimeInterval?
        var minimum: TimeInterval?

        /// Sorted list of all recorded durations.
        var values: [TimeInterval] = []

        mutating func insert(duration: TimeInterval, taskId: NSManagedObjectID) {
            values.insert(duration, at: insertionIndex(for: duration))
            median = values[values.count / 2]
            if let maximum = self.maximum {
                self.maximum = max(maximum, duration)
            } else {
                self.maximum = duration
            }
            if let minimum = self.minimum {
                self.minimum = min(minimum, duration)
            } else {
                self.minimum = duration
            }
        }

        private func insertionIndex(for duration: TimeInterval) -> Int {
            var lowerBound = 0
            var upperBound = values.count
            while lowerBound < upperBound {
                let mid = lowerBound + (upperBound - lowerBound) / 2
                if values[mid] == duration {
                    return mid
                } else if values[mid] < duration {
                    lowerBound = mid + 1
                } else {
                    upperBound = mid
                }
            }
            return lowerBound
        }
    }

    struct RedirectsInfo: Sendable {
        /// A single task can be redirected multiple times.
        var count: Int = 0
        var timeLost: TimeInterval = 0
        var taskIds: [NSManagedObjectID] = []

        init() {}
    }

    struct FailuresInfo: Sendable {
        var count: Int { taskIds.count }
        var taskIds: [NSManagedObjectID] = []

        init() {}
    }
}

#endif
