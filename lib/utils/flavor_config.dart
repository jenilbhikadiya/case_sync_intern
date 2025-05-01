enum Flavor {
  production,
  staging,
}

class FlavorConfig {
  final Flavor flavor;
  final String baseUrl;
  final String appName;

  static FlavorConfig? _instance;

  factory FlavorConfig({
    required Flavor flavor,
    required String baseUrl,
    required String appName,
  }) {
    _instance ??= FlavorConfig._internal(
      flavor: flavor,
      baseUrl: baseUrl,
      appName: appName,
    );
    return _instance!;
  }

  FlavorConfig._internal({
    required this.flavor,
    required this.baseUrl,
    required this.appName,
  });

  static FlavorConfig get instance {
    return _instance!;
  }

  static bool isProduction() => _instance!.flavor == Flavor.production;
  static bool isStaging() => _instance!.flavor == Flavor.staging;
}
