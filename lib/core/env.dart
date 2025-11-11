import 'package:envied/envied.dart';
part 'env.g.dart';

@Envied(obfuscate: true, path: '.env')
abstract class Env {
  @EnviedField(varName: 'OWM_API_KEY')
  static final String owmApiKey = _Env.owmApiKey;
}
