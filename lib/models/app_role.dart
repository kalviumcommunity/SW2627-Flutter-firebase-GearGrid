enum AppRole {
  client,
  admin;

  String get storageValue => name;

  static AppRole fromStorage(String? value) => switch (value) {
    'admin' => AppRole.admin,
    _ => AppRole.client,
  };

  String get label => switch (this) {
    AppRole.client => 'Client',
    AppRole.admin => 'Admin',
  };

  String get title => switch (this) {
    AppRole.client => 'Book gear with confidence',
    AppRole.admin => 'Run dispatch like a live production room',
  };

  String get subtitle => switch (this) {
    AppRole.client =>
      'Browse available inventory, lock your event slot, and track requests in one polished flow.',
    AppRole.admin =>
      'See inventory, approvals, schedules, and dispatch movement without juggling phone calls.',
  };
}
