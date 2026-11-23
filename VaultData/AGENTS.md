# VaultData - Agent Instructions

## Purpose

VaultData implements data persistence and repository access for the Vault application.

It manages CoreData and the underlying persistence infrastructure, including CloudKit integration.

## Responsibilities

- Define CoreData entities and managed object models.
- Implement repository abstractions.
- Handle persistence operations.
- Configure persistent containers.
- Manage local persistence.
- Integrate with CloudKit.
- Handle persistence-related errors.

## Architectural Rules

- May depend on VaultDomain.
- Must not depend on VaultApp.
- Must not contain UIKit or SwiftUI code.
- Must not implement presentation logic.
- Keep CoreData implementation details inside this package.

## CoreData Guidelines

- Follow existing repository conventions.
- Preserve entity relationships.
- Use Decimal for financial amounts.
- Avoid unnecessary fetches and duplicate queries.
- Consider migration compatibility before changing the CoreData model.

## CloudKit Guidelines

- Preserve CloudKit compatibility.
- Consider synchronization implications of schema changes.
- Avoid destructive migrations.
- Never assume local persistence and CloudKit synchronization are immediately consistent.
- Preserve existing synchronization behavior.

## Before Making Changes

Inspect existing entities, repositories, persistence configuration and CloudKit setup.

Evaluate migration and synchronization risks before modifying the data model.
