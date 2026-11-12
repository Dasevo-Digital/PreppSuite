/// Limits apply to incoming bytes, before decoding or authentication.
/// Streaming archives and backups have their own format-specific budgets.
const maxImportBytes = 8 * 1024 * 1024;
const maxImportRows = 10000;
const maxXmlDepth = 64;
const maxXmlElements = 100000;
const maxSnapshotBytes = 64 * 1024 * 1024;
const maxHouseholdMetadataBytes = 1024 * 1024;

/// One picture in the shared folder, sealed and in Base64 (#376). Photos
/// are kept at up to 2000 pixels and come to well under a megabyte; this
/// is room for an unusual one, not a target.
const maxFolderPhotoBytes = 24 * 1024 * 1024;
