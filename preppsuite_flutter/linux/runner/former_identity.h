#ifndef RUNNER_FORMER_IDENTITY_H_
#define RUNNER_FORMER_IDENTITY_H_

// Copies the secure storage entry from FORMER_APPLICATION_ID to
// APPLICATION_ID, once. See former_identity.cc.
void take_over_former_keyring();

#endif  // RUNNER_FORMER_IDENTITY_H_
