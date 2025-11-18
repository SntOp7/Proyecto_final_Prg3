# 🚀 Sistema de Gestión de Hackathon Colaborativa

<div align="center">

![Elixir](https://img.shields.io/badge/Elixir-4B275F?style=for-the-badge&logo=elixir&logoColor=white)
![Erlang](https://img.shields.io/badge/Erlang-A90533?style=for-the-badge&logo=erlang&logoColor=white)
![Version](https://img.shields.io/badge/version-1.0.0-blue?style=for-the-badge)
![License](https://img.shields.io/badge/license-GNU_GPL_v3-green?style=for-the-badge)

**Aplicación distribuida desarrollada en Elixir para la gestión integral de eventos Hackathon**

[Características](#-características-principales) • [Instalación](#️-instalación) • [Uso](#-uso-del-sistema) • [Documentación](#-documentación) • [Equipo](#-equipo-de-desarrollo)

</div>

---

## 📋 Tabla de Contenidos

- [Descripción General](#-descripción-general)
- [Características Principales](#-características-principales)
- [Arquitectura del Sistema](#️-arquitectura-del-sistema)
- [Requisitos del Sistema](#-requisitos-del-sistema)
- [Instalación](#️-instalación)
- [Uso del Sistema](#-uso-del-sistema)
- [Módulos Funcionales](#-módulos-funcionales)
- [Comandos Disponibles](#-comandos-disponibles)
- [Arquitectura Distribuida](#-arquitectura-distribuida)
- [Seguridad](#-seguridad)
- [Documentación](#-documentación)
- [Contribuciones](#-contribuciones)
- [Equipo de Desarrollo](#-equipo-de-desarrollo)
- [Licencia](#-licencia)
- [Contacto](#-contacto)

---

## 🎯 Descripción General

El **Sistema de Gestión de Hackathon Colaborativa** es una aplicación distribuida desarrollada en **Elixir** que facilita la organización y colaboración durante eventos de hackathon tipo Code4Future. La plataforma proporciona una solución centralizada para la gestión de equipos, proyectos, comunicación en tiempo real y mentoría.

### 🌟 Propósito

Durante eventos de 48 horas donde estudiantes, desarrolladores y emprendedores crean soluciones tecnológicas innovadoras, los organizadores enfrentan desafíos críticos:
- ❌ Gestión compleja de la comunicación entre participantes
- ❌ Dificultad en la formación y seguimiento de equipos
- ❌ Falta de registro centralizado de ideas y proyectos
- ❌ Ausencia de seguimiento de avances en tiempo real

Esta plataforma resuelve estos problemas proporcionando una infraestructura robusta, escalable y distribuida.

---

## ✨ Características Principales

### 👥 Gestión de Equipos
- ✅ Registro de participantes con validación de datos
- ✅ Creación de equipos por afinidad o tema
- ✅ Asignación automática de miembros
- ✅ Listado de equipos activos en tiempo real
- ✅ Persistencia completa en formato CSV

### 📊 Gestión de Proyectos
- ✅ Registro de ideas con descripción y categorización
- ✅ Actualización de avances en tiempo real
- ✅ Consulta por categoría o estado
- ✅ Historial completo de progreso
- ✅ Estados del proyecto (desarrollo, completado, suspendido, cancelado)

### 💬 Comunicación en Tiempo Real
- ✅ Sistema de mensajería por equipo usando Phoenix.PubSub
- ✅ Canal general para anuncios de la organización
- ✅ Salas temáticas de discusión
- ✅ Comunicación instantánea sin latencia

### 🎓 Sistema de Mentoría
- ✅ Registro especializado de mentores
- ✅ Canal de consultas equipo-mentor
- ✅ Retroalimentación almacenada permanentemente
- ✅ Asignación dinámica de mentores por especialidad

### 🔐 Seguridad Avanzada
- ✅ Autenticación robusta con tokens únicos
- ✅ Cifrado SHA-256 de contraseñas
- ✅ Control de permisos por roles (participante, mentor, admin)
- ✅ Auditoría completa de seguridad
- ✅ Gestión de sesiones en memoria (ETS)

### 🌐 Arquitectura Distribuida
- ✅ Soporte para múltiples nodos (Central, Persistencia, CLI)
- ✅ Comunicación RPC entre nodos
- ✅ Tolerancia a fallos con supervisores OTP
- ✅ Escalabilidad horizontal
- ✅ Alta disponibilidad

---



## 🏗️ Arquitectura del Sistema

```
┌─────────────────────────────────────────────────────────┐
│                    NODO CENTRAL                         │
│  ┌──────────────────────────────────────────────────┐   │
│  │  • Lógica de Negocio                             │   │
│  │  • Autenticación y Autorización                  │   │
│  │  • Phoenix.PubSub (Mensajería)                   │   │
│  │  • Coordinación de Procesos                      │   │
│  └──────────────────────────────────────────────────┘   │
└─────────────────────┬───────────────────────────────────┘
                      │ RPC
                      ▼
┌─────────────────────────────────────────────────────────┐
│                NODO DE PERSISTENCIA                     │
│  ┌──────────────────────────────────────────────────┐   │
│  │  • Almacenamiento CSV                            │   │
│  │  • Validación de Datos                           │   │
│  │  • Respaldos Automáticos                         │   │
│  │  • Integridad de Archivos                        │   │
│  └──────────────────────────────────────────────────┘   │
└─────────────────────┬───────────────────────────────────┘
                      │
        ┌─────────────┼─────────────┐
        ▼             ▼             ▼
    ┌───────┐    ┌───────┐    ┌───────┐
    │ CLI 1 │    │ CLI 2 │    │ CLI N │
    └───────┘    └───────┘    └───────┘
    Interfaz      Interfaz     Interfaz
    Usuario       Usuario      Usuario
```

### 🔧 Componentes Principales

```
ProyectoFinalPrg3/
├── lib/
│   ├── adapters/           # Capa de adaptadores
│   │   ├── cli/            # Interfaz CLI
│   │   ├── logging/        # Sistema de logs
│   │   ├── network/        # Comunicación distribuida
│   │   ├── persistence/    # Almacenamiento CSV
│   │   └── security/       # Autenticación y seguridad
│   ├── domain/             # Modelos del dominio
│   │   ├── participant.ex
│   │   ├── team.ex
│   │   ├── project.ex
│   │   └── mentor.ex
│   └── services/           # Lógica de negocio
│       ├── auth_service.ex
│       ├── team_manager.ex
│       └── project_manager.ex
├── config/                 # Configuración
├── data/                   # Persistencia CSV
└── logs/                   # Registros del sistema
```

---

## 💻 Requisitos del Sistema

### Hardware Mínimo
- **Procesador:** Intel Core i3 o superior
- **RAM:** 4 GB (recomendado 8 GB)
- **Almacenamiento:** 500 MB disponibles
- **Red:** Conexión a internet estable

### Software Requerido
- **Sistema Operativo:** Windows 10/11, macOS 10.15+, Linux (Ubuntu 20.04+)
- **Erlang/OTP:** Versión 24.0 o superior (requisito fundamental)
- **Elixir:** Versión 1.14 o superior
- **Git:** Para control de versiones

---

## ⚙️ Instalación

### 1️⃣ Clonar el Repositorio

```bash
git clone https://github.com/SntOp7/Proyecto_final_Prg3.git
cd Proyecto_final_Prg3
```

### 2️⃣ Instalar Dependencias

```bash
mix deps.get
mix deps.compile
```

### 3️⃣ Compilar el Proyecto

```bash
mix compile
```

### 4️⃣ Iniciar el Sistema

#### Opción A: Nodo de Persistencia (Iniciar primero)
```bash
iex --sname persistencia -S mix
```

#### Opción B: Nodo Central (Iniciar segundo)
```bash
iex --sname central -S mix
```

#### Opción C: Interfaz CLI (Iniciar al final)
```bash
mix run cli.exs
```

> **⚠️ Importante:** El orden de inicio recomendado es:
> 1. Nodo de Persistencia
> 2. Nodo Central
> 3. CLI (puede iniciar múltiples instancias)

---

## 🎮 Uso del Sistema

### Primer Uso

Al iniciar la CLI, verás:
```
CLI lista (/help para ver comandos)
>
```

### 1️⃣ Registro de Usuario

```bash
> /register nombre="Juan José García" correo=juan@hack.com username=juanjo contrasenia=Pass123! rol=participante
```

**Parámetros:**
- `nombre`: Nombre completo (requerido)
- `correo`: Email único (requerido)
- `username`: Usuario único, 3-50 caracteres alfanuméricos (requerido)
- `contrasenia`: Mínimo 6 caracteres (requerido)
- `rol`: `participante` o `mentor` (requerido)

### 2️⃣ Iniciar Sesión

```bash
> /login correo=juan@hack.com contrasenia=Pass123!
```

### 3️⃣ Crear un Equipo

```bash
> /create_team nombre=Titanes categoria=web descripcion="Equipo de desarrollo web"
```

**Categorías disponibles:**
- `web` - Desarrollo web y aplicaciones
- `movil` - Aplicaciones móviles
- `ia` - Inteligencia Artificial y ML
- `educacion` - Soluciones educativas
- `salud` - Tecnología para salud
- `fintech` - Tecnología financiera
- `iot` - Internet de las Cosas
- `gaming` - Videojuegos y entretenimiento

### 4️⃣ Unirse a un Equipo

```bash
> /join equipo=Titanes
```

### 5️⃣ Crear un Proyecto

```bash
> /create_project nombre=TitanesApp descripcion="Plataforma e-commerce con IA" categoria=web equipo=Titanes
```

### 6️⃣ Acceder al Chat del Equipo

```bash
> /chat equipo=Titanes
```

---

## 📦 Módulos Funcionales

### 🔐 Módulo de Autenticación
- Registro de usuarios con validación completa
- Login con cifrado SHA-256
- Gestión de sesiones con tokens únicos
- Control de permisos por rol

### 👥 Módulo de Equipos
- Creación y gestión de equipos
- Asignación de miembros
- Persistencia en `data/equipos.csv`
- Estados: activo, inactivo

### 📊 Módulo de Proyectos
- Registro de proyectos por equipo
- Seguimiento de avances
- Estados: en_desarrollo, completado, suspendido, cancelado
- Persistencia en `data/proyectos.csv`

### 💬 Módulo de Comunicación
- Sistema PubSub con Phoenix
- Canales por equipo: `:team_<id>`
- Canal de mentoría: `:mentor_team_<id>`
- Canal de anuncios: `:announcement_channel`

### 🎓 Módulo de Mentoría
- Registro de mentores especializados
- Envío de retroalimentación
- Persistencia en `data/feedback.csv`
- Asignación por categoría

---

## 🎯 Comandos Disponibles

### Comandos Públicos (Sin Autenticación)

| Comando | Descripción | Ejemplo |
|---------|-------------|---------|
| `/help` | Mostrar ayuda | `/help` |
| `/register` | Registrar usuario | `/register nombre="..." correo=... username=... contrasenia=... rol=...` |
| `/login` | Iniciar sesión | `/login correo=... contrasenia=...` |

### Comandos de Participante

| Comando | Descripción | Ejemplo |
|---------|-------------|---------|
| `/logout` | Cerrar sesión | `/logout` |
| `/teams` | Listar equipos | `/teams` |
| `/join` | Unirse a equipo | `/join equipo=Titanes` |
| `/create_team` | Crear equipo | `/create_team nombre=... categoria=... descripcion="..."` |
| `/create_project` | Crear proyecto | `/create_project nombre=... descripcion="..." categoria=... equipo=...` |
| `/project` | Ver proyecto | `/project equipo=Titanes` |
| `/chat` | Acceder al chat | `/chat equipo=Titanes` |

### Comandos de Mentor

| Comando | Descripción | Ejemplo |
|---------|-------------|---------|
| `/feedback` | Enviar retroalimentación | `/feedback proyecto_id=uuid-123 mensaje="Excelente progreso..."` |

### Comandos de Administrador

| Comando | Descripción | Ejemplo |
|---------|-------------|---------|
| `/assign_mentor` | Asignar mentor | `/assign_mentor equipo=Titanes id_mentor=uuid-mentor-123` |
| `/delete_team` | Eliminar equipo | `/delete_team id_equipo=uuid-123` |

---


# 📜 Guía Completa de Comandos del Sistema


---

## 🎯 Comandos del Sistema - Referencia Completa

Esta sección proporciona una referencia exhaustiva de todos los comandos disponibles en el sistema, organizados por categoría y rol de usuario. Cada comando incluye su sintaxis exacta, descripción y ejemplos listos para usar.

---

### 🔹 Inicio Rápido del Sistema

#### Configuración Inicial

**1. Configurar tipo de nodo (editar `config/config.exs`)**

Para **Nodo de Persistencia:**
```elixir
config :proyecto_final_prg3,
  tipo_nodo: :persistencia
```

Para **Nodo Central:**
```elixir
config :proyecto_final_prg3,
  tipo_nodo: :central
```

Para **Nodo CLI:**
```elixir
config :proyecto_final_prg3,
  tipo_nodo: :cli
```

#### Comandos de Inicio

**Terminal 1 - Nodo de Persistencia:**
```bash
iex --sname persistencia -S mix
```

**Terminal 2 - Nodo Central:**
```bash
iex --sname central -S mix
```

**Terminal 3 - CLI (Interfaz de Usuario):**
```bash
mix run cli.exs
```

---

### 🔓 Comandos Públicos (Sin Autenticación)

#### 1. Ayuda del Sistema

```bash
/help
```
**Descripción:** Muestra todos los comandos disponibles según tu rol actual.

---

#### 2. Registro de Usuario

**Registrar Participante:**
```bash
/register nombre="Juan José García" correo=juan@hack.com username=juanjo contrasenia=Pass123! rol=participante
```

**Registrar Mentor:**
```bash
/register nombre="Dr. Ana Torres" correo=ana@mentor.com username=anatorres contrasenia=Mentor123! rol=mentor
```

**Registrar con Caracteres Especiales en Nombre:**
```bash
/register nombre="María José López-García" correo=maria@hack.com username=marialopez contrasenia=Secure456! rol=participante
```

**Parámetros Obligatorios:**
- `nombre`: Nombre completo (usar comillas si contiene espacios)
- `correo`: Email único (formato válido)
- `username`: Usuario único, 3-50 caracteres alfanuméricos
- `contrasenia`: Mínimo 6 caracteres
- `rol`: `participante` o `mentor`

---

#### 3. Inicio de Sesión

**Login Estándar:**
```bash
/login correo=juan@hack.com contrasenia=Pass123!
```

**Login como Mentor:**
```bash
/login correo=ana@mentor.com contrasenia=Mentor123!
```

**Login como Administrador:**
```bash
/login correo=admin@proyecto.local contrasenia=admin123
```

---

### 🔐 Comandos Autenticados (Requieren Sesión)

#### 4. Cerrar Sesión

```bash
/logout
```
**Descripción:** Cierra la sesión actual y limpia el token de autenticación.

---

### 👥 Comandos de Participante

#### 5. Gestión de Equipos

**Listar Todos los Equipos:**
```bash
/teams
```

**Crear Equipo - Desarrollo Web:**
```bash
/create_team nombre=Titanes categoria=web descripcion="Equipo enfocado en desarrollo web moderno"
```

**Crear Equipo - Inteligencia Artificial:**
```bash
/create_team nombre=Innovadores categoria=ia descripcion="Equipo de IA y Machine Learning"
```

**Crear Equipo - Aplicaciones Móviles:**
```bash
/create_team nombre=MobileGenius categoria=movil descripcion="Desarrollo de apps móviles nativas"
```

**Crear Equipo - Educación:**
```bash
/create_team nombre=EduTech categoria=educacion descripcion="Soluciones tecnológicas para educación"
```

**Crear Equipo - Salud:**
```bash
/create_team nombre=HealthCare categoria=salud descripcion="Tecnología aplicada a la salud"
```

**Crear Equipo - FinTech:**
```bash
/create_team nombre=FinGenius categoria=fintech descripcion="Soluciones financieras digitales"
```

**Crear Equipo - IoT:**
```bash
/create_team nombre=SmartDevices categoria=iot descripcion="Internet de las Cosas"
```

**Crear Equipo - Gaming:**
```bash
/create_team nombre=GameMakers categoria=gaming descripcion="Desarrollo de videojuegos"
```

**Unirse a un Equipo:**
```bash
/join equipo=Titanes
```

---

#### 6. Gestión de Proyectos

**Crear Proyecto - E-commerce:**
```bash
/create_project nombre=TitanesApp descripcion="Plataforma de comercio electrónico con IA para recomendaciones personalizadas" categoria=web equipo=Titanes
```

**Crear Proyecto - App Educativa:**
```bash
/create_project nombre=EduAI descripcion="Plataforma educativa con inteligencia artificial adaptativa" categoria=educacion equipo=Innovadores
```

**Crear Proyecto - Salud Digital:**
```bash
/create_project nombre=HealthTracker descripcion="Sistema de monitoreo de salud personal con IoT" categoria=salud equipo=HealthCare
```

**Crear Proyecto - FinTech:**
```bash
/create_project nombre=CryptoWallet descripcion="Billetera digital para criptomonedas con máxima seguridad" categoria=fintech equipo=FinGenius
```

**Crear Proyecto - Juego Móvil:**
```bash
/create_project nombre=SpaceRunner descripcion="Juego de acción espacial para plataformas móviles" categoria=gaming equipo=GameMakers
```

**Ver Información de un Proyecto:**
```bash
/project equipo=Titanes
```

---

#### 7. Sistema de Chat

**Entrar al Chat de un Equipo:**
```bash
/chat equipo=Titanes
```

**Enviar Mensajes (una vez dentro del chat):**
```
Hola equipo, ¿cómo van los avances?
```

```
Necesitamos revisar el módulo de autenticación
```

```
¿Alguien puede ayudarme con la integración de la API?
```

**Ver Historial del Chat:**
```bash
/historial
```

**Salir del Chat:**
```bash
/salir_chat
```

---

#### 8. Registro de Avances (Progress)

**Registrar Avance - Desarrollo Backend:**
```bash
/progress proyecto=TitanesApp titulo="Implementación API REST" descripcion="Se completó el desarrollo de la API REST con autenticación JWT y endpoints CRUD completos" version=1.0
```

**Registrar Avance - Frontend:**
```bash
/progress proyecto=TitanesApp titulo="Interfaz de Usuario" descripcion="Diseño e implementación del frontend responsive con React y Tailwind CSS" version=1.1
```

**Registrar Avance - Base de Datos:**
```bash
/progress proyecto=TitanesApp titulo="Modelo de Datos" descripcion="Diseño y normalización de la base de datos PostgreSQL con migraciones completas" version=1.0
```

**Registrar Avance - Testing:**
```bash
/progress proyecto=TitanesApp titulo="Pruebas Unitarias" descripcion="Implementación de suite de tests con cobertura del 85 por ciento usando ExUnit" version=1.2
```

**Ver Todos los Avances de un Proyecto:**
```bash
/avances proyecto=TitanesApp
```

---

### 🎓 Comandos de Mentor

#### 9. Sistema de Retroalimentación

**Feedback General Positivo:**
```bash
/feedback proyecto=TitanesApp mensaje="Excelente progreso en la implementación. La arquitectura del sistema es sólida y bien estructurada. Recomiendo documentar mejor los endpoints de la API"
```

**Feedback con Recomendaciones:**
```bash
/feedback proyecto=EduAI mensaje="Buen trabajo inicial. Sugerencias: 1) Implementar validación de datos más robusta, 2) Optimizar consultas a la base de datos, 3) Agregar manejo de errores en capa de servicios"
```

**Feedback Técnico:**
```bash
/feedback proyecto=HealthTracker mensaje="La integración con IoT está funcionando bien. Consideren implementar un sistema de cache para reducir latencia. Revisen la documentación de seguridad para datos médicos sensibles"
```

**Feedback de Seguridad:**
```bash
/feedback proyecto=CryptoWallet mensaje="Punto crítico: deben implementar 2FA y encriptación end-to-end para las transacciones. La arquitectura de microservicios es adecuada pero necesita hardening de seguridad"
```

**Feedback de UX:**
```bash
/feedback proyecto=SpaceRunner mensaje="La jugabilidad es divertida pero la curva de aprendizaje es muy pronunciada. Recomiendo agregar un tutorial interactivo y ajustar la dificultad de los primeros niveles"
```

---

### 👑 Comandos de Administrador

#### 10. Gestión de Mentores

**Asignar Mentor a Equipo:**
```bash
/assign_mentor equipo=Titanes id_mentor=uuid-mentor-123
```

**Ejemplo con ID Real (reemplazar con ID generado):**
```bash
/assign_mentor equipo=Titanes id_mentor=a1b2c3d4-e5f6-7890-abcd-ef1234567890
```

---

#### 11. Gestión Administrativa

**Eliminar Equipo:**
```bash
/delete_team id_equipo=uuid-equipo-123
```

---

### 📢 Comandos de Comunicación Global

#### 12. Sistema de Anuncios

**Enviar Anuncio Global (Solo Admin):**
```bash
/announcement mensaje="La hackathon comienza en 10 minutos. Todos los equipos deben estar conectados"
```

**Anuncios de Ejemplo:**

```bash
/announcement mensaje="Recordatorio: La presentación de proyectos será mañana a las 10:00 AM"
```

```bash
/announcement mensaje="Atención: El servidor de bases de datos estará en mantenimiento de 2:00 a 2:30 PM"
```

```bash
/announcement mensaje="¡Felicitaciones! Hemos alcanzado 50 equipos registrados en la hackathon"
```

```bash
/announcement mensaje="Breakout sessions con mentores disponibles en sala virtual 2"
```

**Ver Historial de Anuncios:**
```bash
/announcements
```

---

### 🔧 Comandos de Desarrollo y Depuración

#### Comandos Mix (Desarrollo)

**Compilar Proyecto:**
```bash
mix compile
```

**Instalar Dependencias:**
```bash
mix deps.get
mix deps.compile
```

**Ejecutar Tests:**
```bash
mix test
```

**Tests con Cobertura:**
```bash
mix test --cover
```

**Generar Documentación:**
```bash
mix docs
```

**Análisis Estático (Credo):**
```bash
mix credo --strict
```

**Análisis de Tipos (Dialyzer):**
```bash
mix dialyzer
```

**Limpiar Compilación:**
```bash
mix clean
```

**Formatear Código:**
```bash
mix format
```

---

### 📊 Comandos de Consola Elixir (IEx)

#### Inspección del Sistema

**Ver Nodos Conectados:**
```elixir
Node.list()
```

**Ver Nodo Actual:**
```elixir
Node.self()
```

**Ver Procesos Activos:**
```elixir
Process.list()
```

**Ver Sesiones Activas:**
```elixir
:ets.tab2list(:sesiones_activas)
```

**Ver Mensajes de Chat:**
```elixir
:ets.tab2list(:chat_mensajes)
```

**Limpiar Consola:**
```elixir
IEx.Helpers.clear()
```

**Recompilar Módulos:**
```elixir
recompile()
```

---

### 🎭 Escenarios de Uso Completos

#### Escenario 1: Registro y Creación de Equipo

```bash
# 1. Registrarse como participante
/register nombre="Carlos Ruiz" correo=carlos@hack.com username=carlosruiz contrasenia=Pass456! rol=participante

# 2. Iniciar sesión
/login correo=carlos@hack.com contrasenia=Pass456!

# 3. Crear equipo
/create_team nombre=Innovadores categoria=ia descripcion="Equipo de Inteligencia Artificial"

# 4. Ver equipos disponibles
/teams

# 5. Crear proyecto
/create_project nombre=SmartAI descripcion="Sistema de IA para análisis predictivo" categoria=ia equipo=Innovadores
```

---

#### Escenario 2: Colaboración en Equipo

```bash
# Usuario 1 crea el equipo
/register nombre="Ana García" correo=ana@hack.com username=anagarcia contrasenia=Ana123! rol=participante
/login correo=ana@hack.com contrasenia=Ana123!
/create_team nombre=WebDevs categoria=web descripcion="Desarrollo web full-stack"

# Usuario 2 se une al equipo
/register nombre="Luis Martínez" correo=luis@hack.com username=luismartinez contrasenia=Luis456! rol=participante
/login correo=luis@hack.com contrasenia=Luis456!
/join equipo=WebDevs

# Usuario 1 crea el proyecto
/create_project nombre=EcommercePro descripcion="Plataforma e-commerce completa" categoria=web equipo=WebDevs

# Ambos usuarios acceden al chat
/chat equipo=WebDevs
```

---

#### Escenario 3: Mentoría Completa

```bash
# Mentor se registra
/register nombre="Dr. Patricia Rojas" correo=patricia@mentor.com username=patriciarojas contrasenia=Mentor789! rol=mentor
/login correo=patricia@mentor.com contrasenia=Mentor789!

# Admin asigna mentor a equipo
/login correo=admin@proyecto.local contrasenia=admin123
/assign_mentor equipo=WebDevs id_mentor=<id-del-mentor>

# Mentor envía feedback
/login correo=patricia@mentor.com contrasenia=Mentor789!
/feedback proyecto=EcommercePro mensaje="Excelente arquitectura. Recomiendo implementar sistema de caché y optimizar queries SQL para mejorar performance"
```

---

#### Escenario 4: Registro de Avances

```bash
# Login como participante del proyecto
/login correo=ana@hack.com contrasenia=Ana123!

# Registrar múltiples avances
/progress proyecto=EcommercePro titulo="Backend API" descripcion="API REST completa con autenticación JWT y CRUD de productos" version=1.0

/progress proyecto=EcommercePro titulo="Frontend React" descripcion="Interfaz responsive con React, Redux y Material-UI" version=1.1

/progress proyecto=EcommercePro titulo="Integración Pagos" descripcion="Integración con Stripe para procesamiento de pagos" version=1.2

# Ver todos los avances
/avances proyecto=EcommercePro
```

---

### 📝 Plantillas de Comandos Reutilizables

#### Plantilla: Crear Usuario y Equipo

```bash
# Reemplazar: NOMBRE, CORREO, USERNAME, PASSWORD, EQUIPO, CATEGORIA, DESCRIPCION

/register nombre="NOMBRE" correo=CORREO username=USERNAME contrasenia=PASSWORD rol=participante
/login correo=CORREO contrasenia=PASSWORD
/create_team nombre=EQUIPO categoria=CATEGORIA descripcion="DESCRIPCION"
/create_project nombre=PROYECTO descripcion="DESCRIPCION_PROYECTO" categoria=CATEGORIA equipo=EQUIPO
```

---

#### Plantilla: Unirse y Colaborar

```bash
# Reemplazar: NOMBRE, CORREO, USERNAME, PASSWORD, EQUIPO

/register nombre="NOMBRE" correo=CORREO username=USERNAME contrasenia=PASSWORD rol=participante
/login correo=CORREO contrasenia=PASSWORD
/join equipo=EQUIPO
/chat equipo=EQUIPO
```

---

#### Plantilla: Registro de Avance

```bash
# Reemplazar: PROYECTO, TITULO, DESCRIPCION, VERSION

/progress proyecto=PROYECTO titulo="TITULO" descripcion="DESCRIPCION" version=VERSION
```

---

### ⚠️ Errores Comunes y Soluciones

#### Error: "Debes iniciar sesión"
**Solución:**
```bash
/login correo=tu@correo.com contrasenia=tupassword
```

#### Error: "Correo ya registrado"
**Solución:** Usar un correo diferente o iniciar sesión con el existente
```bash
/login correo=correo@existente.com contrasenia=password
```

#### Error: "Equipo ya existente"
**Solución:** Elegir otro nombre para el equipo
```bash
/create_team nombre=OtroNombre categoria=web descripcion="Descripción"
```

#### Error: "No estás en ningún chat"
**Solución:** Ingresar al chat antes de enviar mensajes
```bash
/chat equipo=NombreEquipo
```

#### Error: "El campo X no puede estar vacío"
**Solución:** Usar comillas para textos con espacios
```bash
/create_team nombre=MiEquipo categoria=web descripcion="Esta es una descripción válida"
```

---

### 🔍 Tabla de Referencia Rápida de Categorías

| Categoría | Descripción | Ejemplos de Proyecto |
|-----------|-------------|----------------------|
| `web` | Desarrollo web y aplicaciones | E-commerce, CMS, Portales |
| `movil` | Aplicaciones móviles | Apps nativas, React Native, Flutter |
| `ia` | Inteligencia Artificial y ML | Chatbots, Predicción, Visión por computadora |
| `educacion` | Soluciones educativas | Plataformas LMS, Tutoriales interactivos |
| `salud` | Tecnología para salud | Telemedicina, Registros médicos, Wearables |
| `fintech` | Tecnología financiera | Billeteras digitales, Trading, Blockchain |
| `iot` | Internet de las Cosas | Domótica, Sensores, Automatización |
| `gaming` | Videojuegos | Juegos móviles, Web games, Consolas |

---

### 💡 Tips y Mejores Prácticas

#### 1. Nombres de Equipos
- ✅ Usar nombres cortos y descriptivos
- ✅ Evitar caracteres especiales
- ✅ Sin espacios (usar CamelCase o guiones bajos)
```bash
# ✅ Correcto
/create_team nombre=DataScience categoria=ia descripcion="Análisis de datos"

# ❌ Incorrecto
/create_team nombre="Data Science Team!" categoria=ia descripcion="Análisis"
```

#### 2. Descripciones
- ✅ Siempre usar comillas para descripciones con espacios
- ✅ Ser específico y claro
- ✅ Incluir tecnologías principales
```bash
# ✅ Correcto
/create_project nombre=MiApp descripcion="Aplicación web con React, Node.js y PostgreSQL" categoria=web equipo=MiEquipo

# ❌ Incorrecto
/create_project nombre=MiApp descripcion=App categoria=web equipo=MiEquipo
```

#### 3. Contraseñas
- ✅ Mínimo 6 caracteres
- ✅ Incluir mayúsculas, minúsculas y números
- ✅ Recordar tu contraseña (no hay recuperación automática)

#### 4. Chat
- ✅ Salir del chat cuando termines de usarlo
- ✅ Usar `/historial` para ver mensajes anteriores
- ✅ No enviar mensajes vacíos

---

<div align="center">

**📌 Esta guía está en constante actualización**

Si encuentras algún comando que no funciona como se describe, por favor reporta el problema.

[⬆ Volver al inicio del documento](#-guía-completa-de-comandos-del-sistema)

</div>

---

## 🌐 Arquitectura Distribuida

### Topología del Cluster

El sistema utiliza una arquitectura de nodos distribuidos con las siguientes características:

#### 🔹 Nodo Central
- Gestión de lógica de negocio
- Autenticación y autorización
- Coordinación de procesos
- Phoenix.PubSub para mensajería

#### 🔹 Nodo de Persistencia
- Almacenamiento CSV
- Validación de datos
- Respaldos automáticos
- Integridad de archivos

#### 🔹 Nodos CLI
- Interfaz de usuario
- Múltiples instancias simultáneas
- Conexión a nodos centrales

### Comunicación RPC

```elixir
:rpc.call(
  :"persistencia@hostname",
  ProyectoFinalPrg3.Adapters.Persistence.TeamStore,
  :listar_equipos,
  []
)
```

### Tolerancia a Fallos

El sistema implementa supervisores OTP con estrategia `one_for_one`:

```elixir
Supervisor.start_link(children,
  strategy: :one_for_one,
  name: ProyectoFinalPrg3.Supervisor
)
```

**Comportamiento ante fallos:**
- Proceso individual → Reinicio automático
- Nodo de persistencia → Reintentos de conexión
- Nodo central → Sesiones se pierden, datos persisten

---

## 🔒 Seguridad

### Autenticación
- ✅ Hash SHA-256 para contraseñas
- ✅ Tokens únicos de sesión (Base64)
- ✅ Validación en cada operación
- ✅ Gestión de sesiones en ETS

### Control de Permisos

| Permiso | Participante | Mentor | Admin |
|---------|--------------|--------|-------|
| Ver equipos | ✅ | ✅ | ✅ |
| Crear equipo | ✅ | ❌ | ✅ |
| Unirse a equipo | ✅ | ❌ | ✅ |
| Ver proyecto | ✅ | ✅ | ✅ |
| Crear proyecto | ✅ | ❌ | ✅ |
| Enviar feedback | ❌ | ✅ | ✅ |
| Asignar mentor | ❌ | ❌ | ✅ |
| Eliminar equipo | ❌ | ❌ | ✅ |

### Auditoría

Todos los eventos de seguridad se registran en:
```
logs/security_audit_log.csv
```

Información registrada:
- Timestamp del evento
- Acción ejecutada
- Usuario involucrado
- Rol del usuario
- Estado de la operación
- Detalles adicionales

---

## 📚 Documentación

### Archivos Disponibles
- 📖 **Manual de Usuario** (`MANUAL DE USUARIO.pdf`) - Guía completa para usuarios finales
- 📋 **Especificación del Proyecto** (`Proyecto Final P3 - 2025-2.pdf`) - Requisitos y alcance
- 💾 **Estructura de Datos** - Documentación en `/docs/data_structures.md`

### Estructura de Persistencia

```
data/
├── participantes.csv    # Usuarios participantes
├── mentores.csv         # Usuarios mentores
├── equipos.csv          # Equipos registrados
├── proyectos.csv        # Proyectos de equipos
├── categorias.csv       # Categorías de proyectos
├── feedback.csv         # Retroalimentación
└── progress.csv         # Avances de proyectos
```

### Logs del Sistema

```
logs/
├── event_log.csv           # Eventos generales
└── security_audit_log.csv  # Auditoría de seguridad
```

---

## 🤝 Contribuciones

Las contribuciones son bienvenidas siguiendo estas directrices:

### 🔹 Proceso de Contribución

1. **Fork del repositorio**
2. **Crear rama de característica**
   ```bash
   git checkout -b feature/nueva-caracteristica
   ```
3. **Realizar commits descriptivos**
   ```bash
   git commit -m "feat: añadir sistema de notificaciones"
   ```
4. **Push a la rama**
   ```bash
   git push origin feature/nueva-caracteristica
   ```
5. **Crear Pull Request**

### 🔹 Estándares de Código
- ✅ Seguir convenciones de Elixir
- ✅ Documentar funciones públicas
- ✅ Escribir tests para nuevas características
- ✅ Mantener cobertura de tests > 80%

### 🔹 Commits Mínimos
> **⚠️ Importante:** Cada integrante debe realizar mínimo **15 commits** significativos

---

## 👨‍💻 Equipo de Desarrollo

<div align="center">

### **Equipo de Trabajo**

</div>

| Nombre | Rol | GitHub | Email |
|--------|-----|--------|-------|
| **Sharif Giraldo Obando** | Desarrollador| [@SharifG23o](https://github.com/SharifG23o) | sharif.giraldoo@uqvirtual.edu.co |
| **Juan Sebastián Hernández Guevara** | Desarrollador| [@username](https://github.com/username) | juan.hernandezg@uqvirtual.edu.co |
| **Santiago Ospina Sánchez** | Desarrollador| [@SntOp7](https://github.com/SntOp7) | santiago.ospinas@uqvirtual.edu.co |

### 🎓 Información Académica
- **Universidad:** Universidad del Quindío
- **Programa:** Ingeniería de Sistemas y Computación
- **Asignatura:** Programación III (02D)
- **Periodo:** 2025-2
- **Profesor:** Jhan Carlos Martínez Ceballos

---

## 📄 Licencia

Este proyecto está licenciado bajo la **GNU General Public License v3.0**.

```
Copyright (C) 2025 

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.
```

Ver el archivo [LICENSE](LICENSE) para más detalles.

---

## 📧 Contacto

### Soporte Técnico
Para asistencia técnica o reportar problemas:

📧 **Email de Soporte:**
- sharif.giraldoo@uqvirtual.edu.co
- juan.hernandezg@uqvirtual.edu.co
- santiago.ospinas@uqvirtual.edu.co

### Reportar Errores
Para reportar bugs, incluye:
1. Descripción detallada del error
2. Comando ejecutado
3. Mensaje de error recibido
4. Logs relevantes (`logs/event_log.csv`)
5. Capturas de pantalla (si aplica)

### Sugerencias de Mejora
Las ideas para nuevas funcionalidades son bienvenidas. Envía tus propuestas al correo de soporte.

---

<div align="center">

**⭐ Si este proyecto te resulta útil, considera darle una estrella en GitHub ⭐**

Hecho con ❤️ por el equipo de trabajo

**Universidad del Quindío - 2025**

[⬆ Volver arriba](#-sistema-de-gestión-de-hackathon-colaborativa)

</div>
