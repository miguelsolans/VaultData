//
//  PersistenceChangeNotifier.swift
//  VaultData
//
//  Created by Miguel Solans on 02/08/2026.
//

import CloudKit
import CoreData
import Foundation
import VaultDomain

public final class PersistenceChangeNotifier: PersistenceChangeObserving {
    private let notificationCenter: NotificationCenter
    private let persistenceController: PersistenceController
    private let lock = NSLock()

    private var observers: [ObjectIdentifier: WeakPersistenceChangeObserver] = [:]
    private var currentState: PersistenceSyncState = .storeLoading
    private var activeImportIDs: Set<UUID> = []
    private var hasResolvedInitialImport = false
    private var currentImportBatchFailed = false

    init(
        persistenceContainer: PersistenceController,
        notificationCenter: NotificationCenter = .default
    ) {
        self.notificationCenter = notificationCenter
        self.persistenceController = persistenceContainer

        notificationCenter.addObserver(
            self,
            selector: #selector(storeDidChange),
            name: .NSPersistentStoreRemoteChange,
            object: persistenceContainer.container.persistentStoreCoordinator
        )

        notificationCenter.addObserver(
            self,
            selector: #selector(cloudKitEventChanged(_:)),
            name: NSPersistentCloudKitContainer.eventChangedNotification,
            object: persistenceContainer.container
        )
    }

    public var syncState: PersistenceSyncState {
        withLock { currentState }
    }

    public func addObserver(
        _ observer: PersistenceChangeObserver,
        replayCurrentState: Bool = true
    ) {
        withLock {
            observers[ObjectIdentifier(observer)] = WeakPersistenceChangeObserver(observer)
        }

        guard replayCurrentState else { return }

        DispatchQueue.main.async { [weak self, weak observer] in
            guard let self, let observer, self.isRegistered(observer) else { return }
            observer.persistenceChangeDidOccur(.syncStateChanged(self.syncState))
        }
    }

    public func removeObserver(_ observer: PersistenceChangeObserver) {
        _ = withLock {
            observers.removeValue(forKey: ObjectIdentifier(observer))
        }
    }

    func storeDidLoad() {
        let shouldPublish = withLock { () -> Bool in
            guard currentState == .storeLoading else { return false }
            currentState = .storeLoaded
            return true
        }

        if shouldPublish {
            publish(.syncStateChanged(.storeLoaded))
        }
    }

    public func checkCloudKitAccount() async -> CloudKitAccountAvailability {
        setSyncState(.checkingAccount, unlessInitialImportResolved: true)

        let availability: CloudKitAccountAvailability

        do {
            availability = Self.availability(
                for: try await CKContainer(
                    identifier: persistenceController.cloudKitContainerIdentifier
                ).accountStatus()
            )
        } catch {
            availability = .couldNotDetermine
        }

        let stateToPublish = withLock { () -> PersistenceSyncState? in
            guard !hasResolvedInitialImport else { return nil }

            let state: PersistenceSyncState
            if availability == .available {
                state = activeImportIDs.isEmpty ? .waitingForImport : .importInProgress
            } else {
                state = .accountUnavailable(availability)
            }

            currentState = state
            return state
        }

        if let stateToPublish {
            publish(.syncStateChanged(stateToPublish))
        }

        return availability
    }

    public func retryCloudKitSyncCheck() async -> CloudKitAccountAvailability {
        withLock {
            if currentState != .importSucceeded && activeImportIDs.isEmpty {
                hasResolvedInitialImport = false
                currentImportBatchFailed = false
            }
        }

        return await checkCloudKitAccount()
    }

    @objc
    private func storeDidChange(_ notification: Notification) {
        publish(.dataChanged)
    }

    @objc
    private func cloudKitEventChanged(_ notification: Notification) {
        guard let event = notification.userInfo?[
            NSPersistentCloudKitContainer.eventNotificationUserInfoKey
        ] as? NSPersistentCloudKitContainer.Event else {
            return
        }

        guard event.type == .import else { return }

        let state = withLock { () -> PersistenceSyncState in
            if event.endDate == nil {
                if activeImportIDs.isEmpty {
                    currentImportBatchFailed = false
                }

                activeImportIDs.insert(event.identifier as UUID)
                currentState = .importInProgress
                return currentState
            }

            activeImportIDs.remove(event.identifier as UUID)
            currentImportBatchFailed = currentImportBatchFailed || !event.succeeded

            guard activeImportIDs.isEmpty else {
                currentState = .importInProgress
                return currentState
            }

            hasResolvedInitialImport = true
            currentState = currentImportBatchFailed ? .importFailed : .importSucceeded
            return currentState
        }

        if !event.succeeded {
            print("PersistenceChangeNotifier | Import failed: \(event.error?.localizedDescription ?? "Unknown error")")
        }

        publish(.syncStateChanged(state))
    }

    private func setSyncState(
        _ state: PersistenceSyncState,
        unlessInitialImportResolved: Bool
    ) {
        let stateToPublish = withLock { () -> PersistenceSyncState? in
            if unlessInitialImportResolved && hasResolvedInitialImport {
                return nil
            }

            currentState = state
            return state
        }

        if let stateToPublish {
            publish(.syncStateChanged(stateToPublish))
        }
    }

    private func publish(_ change: PersistenceChange) {
        let activeObservers = withLock {
            observers = observers.filter { $0.value.observer != nil }
            return observers.values.compactMap(\.observer)
        }

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }

            let changeToDeliver: PersistenceChange
            if case .syncStateChanged = change {
                changeToDeliver = .syncStateChanged(self.syncState)
            } else {
                changeToDeliver = change
            }

            activeObservers
                .filter { self.isRegistered($0) }
                .forEach { $0.persistenceChangeDidOccur(changeToDeliver) }
        }
    }

    private func isRegistered(_ observer: PersistenceChangeObserver) -> Bool {
        withLock {
            observers[ObjectIdentifier(observer)]?.observer === observer
        }
    }

    private func withLock<T>(_ body: () -> T) -> T {
        lock.lock()
        defer { lock.unlock() }
        return body()
    }

    private static func availability(for status: CKAccountStatus) -> CloudKitAccountAvailability {
        switch status {
        case .available:
            return .available
        case .noAccount:
            return .noAccount
        case .restricted:
            return .restricted
        case .temporarilyUnavailable:
            return .temporarilyUnavailable
        case .couldNotDetermine:
            return .couldNotDetermine
        @unknown default:
            return .couldNotDetermine
        }
    }

    deinit {
        notificationCenter.removeObserver(self)
    }
}

private final class WeakPersistenceChangeObserver {
    weak var observer: PersistenceChangeObserver?

    init(_ observer: PersistenceChangeObserver) {
        self.observer = observer
    }
}
