//
//  PersistenceChangeNotifier.swift
//  VaultCore
//
//  Created by Miguel Solans on 02/08/2026.
//

import CoreData

public extension Notification.Name {

    static let importSuccessful = Notification.Name("CoreDataImportSuccessful")
    
    static let importError = Notification.Name("CoreDataImportError")

    static let exportSuccessful = Notification.Name("CoreDataExportSuccessful")
    
    static let exportError = Notification.Name("CoreDataExportError")

    static let dataChanged = Notification.Name("CoreDataChanged")

    static let syncDidBecomeIdle = Notification.Name("CoreDataSyncDidBecomeIdle")
}

public final class PersistenceChangeNotifier {

    private let notificationCenter: NotificationCenter

    /// Number of currently running import operations.
    private var activeImports = 0

    /// Debounce timer.
    private var idleTask: Task<Void, Never>?

    /// Prevents posting syncDidBecomeIdle more than once.
    private var hasBecomeIdle = false

    init(
        persistenceContainer: PersistenceController,
        notificationCenter: NotificationCenter = .default
    ) {
        self.notificationCenter = notificationCenter

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

    public func addObserver(
        _ observer: AnyObject,
        selector: Selector,
        name: Notification.Name
    ) {
        notificationCenter.addObserver(
            observer,
            selector: selector,
            name: name,
            object: nil
        )
    }

    public func removeObserver(_ observer: AnyObject) {
        notificationCenter.removeObserver(observer)
    }

    // MARK: - Remote Changes

    @objc
    private func storeDidChange(_ notification: Notification) {

        notificationCenter.post(
            name: .dataChanged,
            object: nil
        )

        // Ignore while CloudKit is still importing.
        guard activeImports == 0 else {
            return
        }

        scheduleIdleCheck()
    }

    // MARK: - CloudKit Events

    @objc
    private func cloudKitEventChanged(_ notification: Notification) {

        guard let event = notification.userInfo?[
            NSPersistentCloudKitContainer.eventNotificationUserInfoKey
        ] as? NSPersistentCloudKitContainer.Event else {
            return
        }

        print("PersistenceChangeNotifier | \(event)")

        switch event.type {

        case .import:

            if event.endDate == nil {

                // Import started.
                activeImports += 1

                idleTask?.cancel()

                print("PersistenceChangeNotifier | Import started (\(activeImports))")

                return
            }

            // Import finished.
            activeImports = max(0, activeImports - 1)

            if event.succeeded {
                notificationCenter.post(name: .importSuccessful, object: nil)
                print("PersistenceChangeNotifier | Import successful")
            } else {
                notificationCenter.post(name: .importError, object: nil)
                print("PersistenceChangeNotifier | Import failed: \(event.error?.localizedDescription ?? "Unknown error")")
            }

            if activeImports == 0 {
                scheduleIdleCheck()
            }

        case .export:

            guard event.endDate != nil else {
                return
            }

            if event.succeeded {
                notificationCenter.post(name: .exportSuccessful, object: nil)
                print("PersistenceChangeNotifier | Export successful")
            } else {
                notificationCenter.post(name: .exportError, object: nil)
                print("PersistenceChangeNotifier | Export failed: \(event.error?.localizedDescription ?? "Unknown error")")
            }

        default:
            break
        }
    }

    // MARK: - Idle Detection

    private func scheduleIdleCheck() {

        guard !hasBecomeIdle else {
            return
        }

        idleTask?.cancel()

        idleTask = Task { [weak self] in

            do {
                try await Task.sleep(for: .seconds(1))
                try Task.checkCancellation()
            } catch {
                return
            }

            guard let self else { return }

            guard self.activeImports == 0 else {
                return
            }

            guard !self.hasBecomeIdle else {
                return
            }

            self.hasBecomeIdle = true

            print("PersistenceChangeNotifier | Sync became idle")

            self.notificationCenter.post(
                name: .syncDidBecomeIdle,
                object: nil
            )
        }
    }

    deinit {

        idleTask?.cancel()

        notificationCenter.removeObserver(self)
    }
}
