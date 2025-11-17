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
