# Guía Completa de Instalación, Ejecución y Despliegue - Food Friend

Este documento detalla paso a paso el procedimiento para configurar el entorno de desarrollo, ejecutar **Food Friend** localmente y desplegar la solución en producción (*Vercel* para la web y compilación de *APK* para *Android*).

---

## 1. Requisitos Previos del Sistema

Asegúrese de contar con las siguientes herramientas instaladas en su equipo:

- **Flutter SDK:** Versión 3.24 o superior (canal *stable*). Verifique con:
  ```bash
  flutter doctor
  ```
- **Node.js:** Versión 20.x o superior (se recomienda Node.js 22 para soporte nativo de `--experimental-strip-types` y *WebSocket*).
  ```bash
  node --version
  ```
- **NPM:** Gestor de paquetes incluido con *Node.js*.
- **Google Chrome:** Para depuración y pruebas en la web.
- **Git:** Para control de versiones.
- **Clave de API de Google Gemini:** Obtenga una clave gratuita en [Google AI Studio](https://aistudio.google.com/).

---

## 2. Instalación y Configuración Inicial

### 2.1. Clonar el Repositorio
```bash
git clone https://github.com/luiscu/food-friend.git
cd food-friend
```

### 2.2. Instalar Dependencias del Frontend y Backend
Instale las dependencias de Flutter y las librerías del backend *proxy*:
```bash
# Dependencias de Flutter (Dart)
flutter pub get

# Dependencias de Node.js y Vercel
npm install
```

### 2.3. Configurar Variables de Entorno
Cree un archivo `.env.local` en la raíz del proyecto tomando como referencia `.env.example`:
```bash
cp .env.example .env.local
```

Edite `.env.local` y agregue su clave de *Google AI Studio*:
```env
GEMINI_API_KEY=AIzaSy...TuClaveAqui
PORT=3000
```

> [!IMPORTANT]
> El archivo `.env.local` está incluido en `.gitignore` y nunca debe subirse al repositorio. Las claves se mantienen estrictamente en el entorno de ejecución del servidor.

---

## 3. Ejecución en Modo Desarrollo

Food Friend cuenta con dos opciones para su ejecución local:

### Opción A: Ejecución Simultánea Automatizada (Recomendada)
Para iniciar en paralelo el servidor *proxy* de la API (`http://localhost:3000`) y el servidor web de Flutter (`http://localhost:8080`):
```bash
# Mediante script NPM
npm run dev

# O en Windows PowerShell
.\serve.ps1

# O en símbolo del sistema (CMD)
serve.bat
```

### Opción B: Ejecución en Terminales Separadas
Si prefiere monitorear los registros de cada proceso de forma independiente:

1. **Terminal 1 - Servidor Proxy de API Backend:**
   ```bash
   npm run api
   # Inicia dev-server.mjs en http://localhost:3000
   ```
2. **Terminal 2 - Servidor Flutter Web:**
   ```bash
   flutter run -d chrome
   # O para servidor web desacoplado:
   flutter run -d web-server --web-port 8080 --web-hostname localhost
   ```

---

## 4. Estrategia de Despliegue

### 4.1. Despliegue en la Web con Vercel
El proyecto está optimizado para alojarse directamente en **Vercel**, aprovechando su infraestructura *serverless*:

1. **Compilar el Frontend Web:**
   ```bash
   flutter build web --release
   ```
   Esto genera los archivos estáticos optimizados en la carpeta `build/web/`.

2. **Configuración de Vercel (`vercel.json`):**
   El archivo de configuración en la raíz enruta automáticamente las peticiones de `/api/*` hacia las funciones TypeScript en `api/`, y sirve el contenido de `build/web/` como aplicación de una sola página (*SPA*).

3. **Desplegar mediante Vercel CLI:**
   ```bash
   # Iniciar sesión en Vercel
   npx vercel login

   # Desplegar en entorno de prueba (Preview)
   npx vercel

   # Desplegar a producción
   npx vercel --prod
   ```

4. **Configuración en el Panel de Vercel:**
   - En *Project Settings* > *Environment Variables*, agregue la variable:
     - `GEMINI_API_KEY`: Su clave de producción de *Google AI Studio*.

---

### 4.2. Compilación para Dispositivos Móviles (Android APK)
Para generar el paquete instalable en dispositivos *Android*:

1. **Verificar configuración de Android:**
   Asegúrese de contar con *Android SDK* configurado en su equipo (`flutter doctor`).

2. **Generar el APK optimizado:**
   ```bash
   flutter build apk --release
   ```

3. **Ubicación del Instalable:**
   El archivo binario se generará en:
   ```text
   build/app/outputs/flutter-apk/app-release.apk
   ```

Puede transferir este archivo directamente a cualquier dispositivo móvil *Android* o distribuirlo a través de canales internos de prueba.

