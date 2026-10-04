#include "former_identity.h"

// The plugin's own keyring class, from its include directory (exported
// to the runner through the plugin target). Using it rather than calling
// libsecret directly is the point: the entry has to be found and written
// exactly the way the plugin will look for it.
//
// That matters more than it sounds. `SecretStorage` keeps a `SecretSchema`
// whose name points into its label string as it was at construction;
// `setLabel` then replaces that string, and the name ends up reading
// whatever the string implementation keeps in that spot — on libstdc++
// the capacity of the new label, so the stored `xdg:schema` attribute is
// a single character that depends on the label's length. A lookup written
// against libsecret with the label as the schema name matches nothing.
// Going through the same class makes the same choice, whatever it is.
#include "Secret.hpp"

#include <string>

// flutter_secure_storage keeps every value of this app in one keyring
// entry, labelled "<id>/FlutterSecureStorage" with the account
// "<id>.secureStorage", both built from the GTK application id. Among
// those values is the key the household database is encrypted with.
// Under a new id the plugin would look for a different entry, find
// nothing, and the database would end in recovery: on the disk and not
// to be opened.
//
// So before the app starts, the former entry is copied to the new name.
// Only while the new one is empty, and only copied: the old entry stays.
// A keyring that is locked or unreachable right now is left alone; the
// next start tries again, and nothing has been lost by waiting.
namespace {

void prepare(SecretStorage& storage, const char* id) {
  const std::string label = std::string(id) + "/FlutterSecureStorage";
  const std::string account = std::string(id) + ".secureStorage";
  storage.setLabel(label.c_str());
  storage.addAttribute("account", account.c_str());
}

}  // namespace

void take_over_former_keyring() {
  try {
    // Constructed and labelled the way the plugin does it at
    // registration: default label first, the real one set afterwards.
    SecretStorage current;
    prepare(current, APPLICATION_ID);
    const nlohmann::json present = current.readFromKeyring();
    if (!present.is_object() || !present.empty()) return;

    SecretStorage former;
    prepare(former, FORMER_APPLICATION_ID);
    const nlohmann::json values = former.readFromKeyring();
    if (!values.is_object() || values.empty()) return;

    current.storeToKeyring(values);
  } catch (...) {
    // Locked, refused, or no Secret Service at all. Never a reason not
    // to start.
  }
}
