abstract final class ApiEndpoint {
  static String normalizeBaseUrl(String value) {
    final input = value.trim();
    if (input.isEmpty) throw const FormatException('API address is empty');
    final withScheme =
        input.startsWith('http://') || input.startsWith('https://')
        ? input
        : 'https://$input';
    final uri = Uri.parse(withScheme);
    if (uri.host.isEmpty) throw const FormatException('Invalid API address');
    final path = uri.path.isEmpty || uri.path == '/'
        ? '/'
        : uri.path.endsWith('/')
        ? uri.path
        : '${uri.path}/';
    return Uri(
      scheme: uri.scheme,
      userInfo: uri.userInfo,
      host: uri.host,
      port: uri.hasPort ? uri.port : null,
      path: path,
    ).toString();
  }
}
