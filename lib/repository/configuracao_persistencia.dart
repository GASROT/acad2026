enum OrigemPersistencia { local, remota, offlineFirst }

class ConfiguracaoPersistencia {
  static const _modo = String.fromEnvironment(
    'PERSISTENCIA',
    defaultValue: 'offlineFirst',
  );
  static OrigemPersistencia get origem => switch (_modo) {
    'local' => OrigemPersistencia.local,
    'remota' => OrigemPersistencia.remota,
    _ => OrigemPersistencia.offlineFirst,
  };
}
