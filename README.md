🌦️ App de Clima – Consumo de API REST (OpenWeatherMap)

Aplicación Flutter que consume la API de OpenWeatherMap para mostrar el clima actual de ciudades o municipios de México.
Incluye manejo de .env, estados (cargando, error, vacío), timeout, retry, validación de entrada y sanitización de texto.

🚀 Pasos de instalación y ejecución

1️⃣ Clonar y preparar el proyecto
git clone <tu-repo>
cd api
flutter clean
flutter pub get

2️⃣ Crear archivo .env

En la raíz del proyecto, crea un archivo llamado .env:

OWM_API_KEY=TU_API_KEY_DE_OPENWEATHER


⚠️ No subas este archivo a GitHub.
Asegúrate de tener .env en tu .gitignore.

También crea un .env.example (sin clave real):

OWM_API_KEY=CHANGEME

3️⃣ Generar los archivos de entorno

Ejecuta el generador de ENVied:

dart run build_runner build --delete-conflicting-outputs


Esto generará el archivo:

lib/core/env.g.dart

4️⃣ Verificar permisos en Android

Edita el archivo android/app/src/main/AndroidManifest.xml
y agrega estas líneas fuera del <application>:

<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />

5️⃣ Ejecutar la app

Ejecuta el proyecto:

flutter run


💡 Si aparece el error
Building with plugins requires symlink support,
ejecuta start ms-settings:developers y activa Developer Mode en Windows.

6️⃣ Probar los diferentes estados

Vacío: al abrir sin buscar nada.

Cargando: al consultar clima.

Error: apaga internet o usa una API key errónea.

Éxito: selecciona un municipio (por ejemplo, Querétaro).

Guarda las capturas como:

docs/screens/empty.png
docs/screens/loading.png
docs/screens/error.png
docs/screens/success.png

⚙️ Verificación técnica
Requisito	Cómo se cumple
HTTPS	Todas las peticiones usan Uri.https(...).
Timeout	Implementado con .timeout(const Duration(seconds: 8)) en SafeHttpClient.
Retry	Implementado con reintentos exponenciales (retry()).
Validación	Solo se permite seleccionar ciudades válidas mediante Autocomplete.
Sanitización	Función sanitize() limpia los textos recibidos de la API.
Errores (429, 5xx, sin red)	Capturados y mostrados en ErrorView.
Cache defensiva	Respuestas guardadas por 5 minutos en MemoryCache<Weather>.

🧪 Pruebas recomendadas

Buscar clima de Guadalajara (respuesta exitosa).

Desactivar internet (muestra error).

Forzar API key inválida (verifica manejo de 401/403).

Hacer varias consultas seguidas (usa caché sin nuevos requests).

Consultar “Usar mi ubicación” (verifica permisos de ubicación).

🔒 Buenas prácticas implementadas

.env no se versiona.

Peticiones solo HTTPS.

Textos de API sanitizados.

Timeouts configurados.

Reintentos controlados (retry con backoff).

Errores mostrados en UI sin crashear la app.

Cache en memoria para evitar llamadas excesivas.

Validación de entrada segura.
