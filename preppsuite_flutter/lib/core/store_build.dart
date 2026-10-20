/// Whether this is a build for an app store
/// (`--dart-define=PREPPSUITE_STORE=true`).
///
/// Apple and Google allow tips to a developer only through their own
/// payment, so such a build leaves the Ko-fi link out (#197), as Famio's
/// store builds do. The packages released so far are none: they are
/// downloaded and installed by hand, and keep the link.
const storeBuild = bool.fromEnvironment('PREPPSUITE_STORE');
