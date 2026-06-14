@JS()
library;

import 'dart:js_interop';

extension type _PasswordCredentialInit._(JSObject _) implements JSObject {
  external factory _PasswordCredentialInit({JSString id, JSString password});
}

extension type _PasswordCredential._(JSObject _) implements JSObject {
  external factory _PasswordCredential(_PasswordCredentialInit init);
}

extension type _CredentialsContainer._(JSObject _) implements JSObject {
  external JSPromise<JSAny?> store(JSObject credential);
}

@JS('navigator.credentials')
external _CredentialsContainer? get _credentials;

Future<void> saveCredentials(String email, String password) async {
  try {
    final container = _credentials;
    if (container == null) return;
    final init = _PasswordCredentialInit(
      id: email.toJS,
      password: password.toJS,
    );
    final credential = _PasswordCredential(init);
    await container.store(credential).toDart;
  } catch (_) {
    // API no soportada o usuario rechazó guardar
  }
}
