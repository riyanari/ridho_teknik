String routeForRole(String? role) {
  switch ((role ?? '').toLowerCase()) {
    case 'owner':
      return '/owner';
    case 'klien':
    case 'client':
      return '/klien';
    case 'teknisi':
    case 'technician':
      return '/teknisi';
    default:
      return '/home'; // fallback
  }
}