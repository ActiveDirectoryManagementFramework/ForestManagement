# Changelog

## ???

- Fix: SchemaLdif - "Argument is null or empty" error when using an account with the `<name>@<domain>` format

## 1.5.46 (2022-09-16)

- Upd: ExchangeSchema - added support for pipeline input for invocation
- Upd: Forest Level - added support for pipeline input for invocation
- Upd: Schema - added support for pipeline input for invocation
- Upd: SchemaLdif - added support for pipeline input for invocation
- Upd: Server - added support for pipeline input for invocation
- Upd: SiteLink - added support for pipeline input for invocation
- Upd: SiteLink - renamed change actions to Create, Update and Delete
- Upd: SiteLink - renamed information actions to MultipleSites, TooManySites
- Upd: SiteLink - added actionable information to the Changed property of the test result
- Upd: Sites - added support for pipeline input for invocation
- Upd: Sites - renamed change actions to Create, Update, Rename and Delete
- Upd: Sites - added actionable information to the Changed property of the test result
- Upd: Subnet - added support for pipeline input for invocation
- Upd: Subnet - renamed change actions to Create, Update and Delete
- Upd: Subnet - added actionable information to the Changed property of the test result

## 1.5.31 (2022-03-18)

- Upd: ExchangeSchema - added support for Split Permission mode
- Fix: ExchangeSchema - broken invocation

## 1.5.29 (2021-04-23)

- New: Command Register-FMServer - define settings controlling server-site assignments.
- Upd: Servers - add ability to disable automatic site assignment.

## 1.5.27 (2021-01-15)

- Upd: Added configuration option to disable Schema Credential workflow when using a Credential Provider

## 1.5.26 (2020-10-11)

- New: Certificates Component
- Upd: Removed most dependencies due to bug in PS5.1. Dependencies in ADMF itself are now expected to provide the necessary tools / modules.
- Upd: Incremented PSFramework minimum version.

## 1.4.23 (2020-09-13)

- Removed DomainManagement dependency from manifest, due to bugs in PS5.1

## 1.4.22 (2020-09-11)

- New: Component: Exchange Schema - manage the forest level settings of Exchange.
- New: Component: ForestLevel - manage the forest functional level
- New: Component: Schema Default Permissions - manage the default permissions defined in Schema
- Fix: Unregister-FMSubnet - doesn't do a damn thing
- Fix: Invoke-FMNTAuthStore - will now doublecheck whether certificate was correctly applied

## 1.1.17 (2020-06-19)

- Fix: Test-FMSchema - tries to create defnct attributes

## 1.1.16 (2020-06-12)

- Upd: Added retries after schema credential switch

## 1.1.15 (2020-06-04)

- Upd: Schema Component - changed identifier to OID
- Upd: Schema Component - added IsDefunct property and attribute decommissioning process
- Upd: Schema Component - case sensitive data comparison

## 1.1.12 (2020-04-17)

- New: Component: NTAuthStore certificates can now be deployed and defined via configuration

## 1.0.11 (2020-03-02)

- Upd: Test-FMSchemaLdif - writes a warning when testing an object that has nocreation operation assigned, just modify, and is missing in AD.
- Upd: Register-FMSchemaLdif - supports specifying the order it is applied at and the configuration Context that provided the settings.
- Upd: Register-FMSchemaLdif - supports specifying objects, which will not trigger an alert if they are missing.
- Fix: Test-FMSchemaLdif - fails when comparing certain property-types.
- Fix: Invoke-FMSchemaLdif - respects designed order of application

## 1.0.6 (2020-01-27)

- Metadata update

## 1.0.5 (2019-12-21)

- Initial Release
