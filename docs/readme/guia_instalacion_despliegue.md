# Guía Completa de Instalación, Ejecución y Despliegue - Food Friend

Este documento detalla paso a paso el procedimiento para configurar el entorno de desarrollo, ejecutar **Food Friend** localmente y desplegar la solución en producción (**Vercel** para Web + *Serverless Functions* desde una organización de *GitHub*, y compilación de **APK** para *Android*).

---

## 1. Requisitos Previos del Sistema

Asegúrese de contar con las siguientes herramientas instaladas en su equipo:

- **Flutter SDK:** Versión 3.24 o superior (canal *stable*). Verifique con:
  ```powershell
  flutter doctor
  ```
- **Node.js:** Versión 20.x o 22.x (recomendado Node.js 22).
  ```powershell
  node --version
  ```
- **NPM:** Gestor de paquetes incluido con *Node.js*.
- **Google Chrome:** Para depuración y pruebas en la web.
- **Git:** Para control de versiones.
- **Clave de API de Google Gemini:** Obtenga una clave gratuita en [Google AI Studio](https://aistudio.google.com/).

---

## 2. Instalación y Configuración Inicial

### 2.1. Clonar el Repositorio
```powershell
git clone https://github.com/luiscu/food-friend.git
cd food-friend
```

### 2.2. Instalar Dependencias del *Frontend* y *Backend*
```powershell
# Dependencias de Flutter (Dart)
flutter pub get

# Dependencias de Node.js y Vercel Serverless Functions
npm install
```

### 2.3. Configurar Variables de Entorno
Cree un archivo `.env.local` en la raíz del proyecto tomando como referencia `.env.example`:
```powershell
Copy-Item .env.example .env.local
```

Edite `.env.local` y agregue su clave de *Google AI Studio*:
```env
GEMINI_API_KEY=AIzaSy...TuClaveAqui
PORT=3000
```

> [!IMPORTANT]
> El archivo `.env.local` está incluido en `.gitignore` y nunca debe subirse al repositorio. Las claves se mantienen estrictamente en el entorno del servidor.

---

## 3. Ejecución en Modo Desarrollo

### Opción A: Ejecución Simultánea con Alias Rápido (Recomendada)
Para iniciar en paralelo el servidor *proxy* de la API (`http://localhost:3000`) y el servidor web de Flutter (`http://localhost:8080`):
```powershell
# En Windows PowerShell
.\serve.ps1

# En símbolo del sistema (CMD)
serve.bat

# O mediante NPM
npm run dev
```

### Opción B: Ejecución en Terminales Separadas
1. **Terminal 1 - Servidor *Proxy* de API *Backend*:**
   ```powershell
   npm run api
   # Inicia dev-server.mjs en http://localhost:3000
   ```
2. **Terminal 2 - Servidor Flutter Web:**
   ```powershell
   flutter run -d chrome
   # O como servidor web en puerto fijo:
   flutter run -d web-server --web-port 8080 --web-hostname localhost
   ```

---

## 4. Despliegue en Producción con Vercel (Incluyendo Organizaciones de GitHub y Capa Gratuita)

El proyecto cuenta con configuración automatizada en [`vercel.json`](file:///c:/Users/luisr/food-friend/vercel.json) y [`scripts/build-vercel.sh`](file:///c:/Users/luisr/food-friend/scripts/build-vercel.sh) para compilar Flutter Web y desplegar simultáneamente las funciones *serverless* de `/api/*`.

### 4.1. ¿Se puede desplegar gratis desde una Organización de GitHub?
- **Importación directa desde Organización en UI de Vercel:** En Vercel, conectar directamente un repositorio perteneciente a una *GitHub Organization* desde el panel web suele requerir un equipo *Vercel Pro* (o una prueba de 14 días).
- **Alternativas 100% Gratuitas (Plan *Hobby*):**
  1. **Mediante *Fork* personal (Recomendado para CI/CD automático):** Haga un *fork* del repositorio de la organización hacia su cuenta personal de GitHub e importe ese *fork* desde su cuenta *Hobby* de Vercel.
  2. **Mediante *Vercel CLI* desde su máquina local:** Ejecute `npx vercel --prod` autenticándose con su cuenta personal *Hobby*; esto sube el proyecto directamente sin requerir la facturación de la organización de GitHub.

### 4.2. Configuración de *Serverless Functions* y Límites del Plan Gratuito
- Las funciones ubicadas en `api/health.ts`, `api/recipes.ts`, `api/detect-fridge.ts` y `api/parse-receipt.ts` son detectadas y compiladas automáticamente por `@vercel/node`.
- **Límite de *Payload* (4.5 MB):** En el plan gratuito (*Hobby*), el cuerpo de las peticiones tiene un límite de 4.5 MB, lo cual está cubierto por las validaciones de tamaño implementadas en los *endpoints* de imágenes.
- **Tiempo de Ejecución (*Timeout*):** En el plan *Hobby*, las funciones *serverless* permiten hasta 60 segundos de ejecución, tiempo más que suficiente para `gemini-3.8-flash` (que responde habitualmente en 2 a 6 segundos).

### 4.3. Pasos para Desplegar en Vercel
1. **Desde el Panel Web de Vercel:**
   - Cree un nuevo proyecto (*Add New... > Project*) e importe el repositorio.
   - Vercel detectará automáticamente [`vercel.json`](file:///c:/Users/luisr/food-friend/vercel.json), el cual ejecuta `bash scripts/build-vercel.sh` para instalar el *SDK* de Flutter en el contenedor de construcción y generar `build/web`.
   - En **Environment Variables**, agregue:
     - `GEMINI_API_KEY` = su clave de *Google AI Studio*.
   - Presione **Deploy**.
2. **Desde la Terminal con *Vercel CLI*:**
   ```powershell
   npx vercel login
   npx vercel --prod
   ```

---

## 5. Compilación para Dispositivos Móviles (*Android APK*)

Para generar el archivo instalable `.apk` para dispositivos *Android*:

```powershell
flutter build apk --release
```

El instalador optimizado se generará en:
```text
build/app/outputs/flutter-apk/app-release.apk
```
