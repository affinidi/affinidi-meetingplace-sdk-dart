## Unreleased

### Added

- Channel schema v5 now persists transport-aware channel state through `transport` and unified `messageSyncMarker` fields.

### Changed

- Matrix channel history cursors now use the unified `messageSyncMarker` field instead of a Matrix-specific sync marker column.

## 0.0.1-dev.50

 - **FIX**: persist attachment IDs (#256).

## 0.0.1-dev.49

 - Update a dependency to the latest release.

## 0.0.1-dev.48

 - Update a dependency to the latest release.

## 0.0.1-dev.47

 - Update a dependency to the latest release.

## 0.0.1-dev.46

 - **FIX**: add Matrix transport support alongside DIDComm.

### Changed

- **Chat items database** — New columns: `editedAt`, `transportId`, `isDeleted`, `isDeletedLocally`, `attachments.metadata`.

- **Channel database** — New columns: `transport`, `matrixSyncMarker`.

- **Connection offer database** — New column: `transport`.

## 0.0.1-dev.45

 - **FIX**: add decline zkp request (#227).

## 0.0.1-dev.44

 - Update a dependency to the latest release.

## 0.0.1-dev.43

 - Update a dependency to the latest release.

## 0.0.1-dev.42

 - **FEAT**: add meeting_place_credentials package (#160).

## 0.0.1-dev.41

 - **FEAT**: add VRC/VDIP channel attachment support to meeting_place_core (#196).

## 0.0.1-dev.40

 - **REFACTOR**: database schema and update dependencies (#168).

## 0.0.1-dev.39

 - Update a dependency to the latest release.

## 0.0.1-dev.38

 - **FEAT**: increase HTTP idle timeout for control plane requests (FTL-27059) (#174).

## 0.0.1-dev.37

 - Update a dependency to the latest release.

## 0.0.1-dev.36

 - **FEAT**: convert contact card fields to json blob (#157).

## 0.0.1-dev.35

 - **FEAT**: abstract concierge and event messages (#132).

## 0.0.1-dev.34

 - Update a dependency to the latest release.

## 0.0.1-dev.33

 - Update a dependency to the latest release.

## 0.0.1-dev.32

 - **FIX**: improvements and bug fixes (#131).

## 0.0.1-dev.31

 - **FIX**: quality improvements and resolution of minor bugs (#108).

## 0.0.1-dev.30

 - Update a dependency to the latest release.

## 0.0.1-dev.29

 - Update a dependency to the latest release.

## 0.0.1-dev.28

 - Update a dependency to the latest release.

## 0.0.1-dev.27

 - **FIX**: use timestamp from message body for improved accuracy.

## 0.0.1-dev.26

 - Update a dependency to the latest release.

## 0.0.1-dev.25

 - Update a dependency to the latest release.

## 0.0.1-dev.24

 - Update a dependency to the latest release.

## 0.0.1-dev.23

 - Update a dependency to the latest release.

## 0.0.1-dev.22

 - Update a dependency to the latest release.

## 0.0.1-dev.21

 - Update a dependency to the latest release.

## 0.0.1-dev.20

 - Update a dependency to the latest release.

## 0.0.1-dev.19

 - **FIX**: protocol alignment with standard; replace vCard by contactCard (#42).

## 0.0.1-dev.18

 - Update a dependency to the latest release.

## 0.0.1-dev.17

 - Update a dependency to the latest release.

## 0.0.1-dev.16

 - Update a dependency to the latest release.

## 0.0.1-dev.15

 - Update a dependency to the latest release.

## 0.0.1-dev.14

 - Update a dependency to the latest release.

## 0.0.1-dev.13

 - Update a dependency to the latest release.

## 0.0.1-dev.12

 - **FIX**: allow offer acceptance if existing offer is finalised or if channel is not inaugurated (#18).

## 0.0.1-dev.11

 - **FIX**: apply configured retry count and return network_error code in case of connection error (#16).

## 0.0.1-dev.10

 - Update a dependency to the latest release.

## 0.0.1-dev.9

 - **DOCS**: added Meeting Place banner per SDK (#15).

## 0.0.1-dev.8

 - Update a dependency to the latest release.

## 0.0.1-dev.7

 - Update a dependency to the latest release.

## 0.0.1-dev.6

 - Update a dependency to the latest release.

## 0.0.1-dev.5

 - Update a dependency to the latest release.

## 0.0.1-dev.4

 - **FIX**: expose drift in memory databases (#6).

## 0.0.1-dev.3

 - Update a dependency to the latest release.

## 0.0.1-dev.2

 - Update a dependency to the latest release.

## 0.0.1-dev.1

 - **FIX**: use proper dev version format (#3).

## 0.0.1-dev.0

 - **FEAT**: initial release
