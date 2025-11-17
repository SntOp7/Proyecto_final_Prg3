defmodule ProyectoFinalPrg3.Adapters.Persistence.PersistenceManager do
  @moduledoc """
  Módulo responsable de inicializar y verificar la integridad del sistema
  de persistencia basado en archivos CSV.

  Este módulo reemplaza a los anteriores `Repository` y `Datastore`,
  cumpliendo las responsabilidades de:

    - Crear la carpeta `data/` si no existe.
    - Crear los archivos CSV necesarios.
    - Asegurar que cada archivo tenga el encabezado correcto.
    - Verificar integridad básica antes de iniciar el sistema.

  NO administra datos, NO hace CRUD, NO interactúa con los Stores individuales.
  Los Store siguen siendo los únicos responsables de leer/escribir datos.

  Autores: [Sharif Giraldo Obando, Juan Sebastián Hernández y Santiago Ospina Sánchez]
  Fecha de creación: 2025-11-16
  Fecha de última modificación: 2025-11-16
  Licencia: GNU GPL v3
  """

  alias ProyectoFinalPrg3.Adapters.Logging.LoggerService
  alias ProyectoFinalPrg3.Adapters.Persistence.ParticipantStore
  alias ProyectoFinalPrg3.Domain.Participant
  alias ProyectoFinalPrg3.Adapters.Security.EncryptionAdapter

  # Configuración de archivos CSV necesarios

  @csv_files [
    {:categorias, "categorias.csv",
     "id,nombre,descripcion,proyectos,fecha_creacion,creador_id,activo"},
    {:feedback, "feedback.csv",
     "id,mentor_id,proyecto_id,equipo_id,avance_id,contenido,fecha_creacion,nivel,visibilidad,estado"},
    {:mentores, "mentores.csv",
     "id,nombre,correo,especialidad,biografia,equipos_asignados,disponibilidad,canal_mentoria_id,fecha_registro,retroalimentaciones,rol,activo"},
    {:participantes, "participantes.csv",
     "id,nombre,correo,username,rol,equipo_id,experiencia,fecha_registro,estado,ultima_conexion,mensajes,canales_asignados,token_sesion,perfil_url"},
    {:progress, "progress.csv",
     "id,proyecto_id,equipo_id,titulo,descripcion,fecha_registro,autor_id,estado,retroalimentacion,adjuntos,version"},
    {:proyectos, "proyectos.csv",
     "id,nombre,descripcion,categoria,estado,fecha_creacion,fecha_actualizacion,equipo_id,mentor_id,avances,retroalimentaciones,repositorio_url,puntaje,visibilidad,tags"},
    {:equipos, "equipos.csv",
     "id,nombre,descripcion,categoria,id_proyecto,id_mentor,participantes,fecha_creacion,estado,canal_chat_id,puntaje,historial"}
  ]

  # ============================================================
  # API PÚBLICA
  # ============================================================

  @doc """
  Inicializa todo el sistema de persistencia:

    - Crea carpeta `data/`.
    - Crea CSV faltantes.
    - Asegura encabezados correctos.

  Es la función principal llamada desde `InitBootService`.
  Puede llamarse múltiples veces sin riesgo, ya que solo crea lo que falta.
  Parámetros: Ninguno.
  Retorna: `:ok`.
  """
  def inicializar do
    crear_directorio_data()
    crear_archivos_csv()
    inicializar_usuarios_admin()

    LoggerService.registrar_evento("Persistencia inicializada correctamente", %{
      tipo: :persistencia,
      fecha: DateTime.utc_now()
    })

    :ok
  end

  defp inicializar_usuarios_admin do
    admin_email = "admin@proyecto.local"

    case ParticipantStore.buscar_por_correo(admin_email) do
      nil ->
        admin = %Participant{
          id: UUID.uuid4(),
          nombre: "Admin",
          correo: admin_email,
          username: "admin",
          contrasena: EncryptionAdapter.cifrar("admin123"),
          rol: :administrador,
          equipo_id: nil,
          estado: :activo,
          mensajes: []
        }

        ParticipantStore.guardar_participante(admin)
        LoggerService.registrar_evento("Administrador inicial creado", %{correo: admin_email})

      _ ->
        :ok
    end
  end

  @doc """
  Verifica integridad de todos los archivos:
    - Existencia de archivos CSV necesarios
    - Tengan encabezados válidos
  Si encuentra algún archivo incorrecto, lo repara automáticamente.
  Parámetros: Ninguno.
  Retorna: `:ok`.
  """
  def verificar_integridad do
    Enum.each(@csv_files, fn {_, nombre_archivo, encabezado} ->
      ruta = ruta(nombre_archivo)

      cond do
        # archivo inexistente → crearlo
        not File.exists?(ruta) ->
          LoggerService.registrar_evento("Archivo faltante generado", %{archivo: nombre_archivo})
          File.write!(ruta, encabezado <> "\n")

        # archivo existe pero encabezado incorrecto → repararlo
        encabezado_incorrecto?(ruta, encabezado) ->
          reparar_encabezado(ruta, encabezado)
          LoggerService.registrar_evento("Encabezado reparado", %{archivo: nombre_archivo})

        true ->
          :ok
      end
    end)

    LoggerService.registrar_evento("Integridad de persistencia verificada", %{
      estado: :ok
    })

    :ok
  end

  # ============================================================
  # PRIVADAS — creación y reparación
  # ============================================================

  @doc false
  defp crear_directorio_data do
    File.mkdir_p!("data")
  end

  @doc false
  defp crear_archivos_csv do
    Enum.each(@csv_files, fn {_key, nombre_archivo, encabezado} ->
      ruta = ruta(nombre_archivo)

      if not File.exists?(ruta) do
        File.write!(ruta, encabezado <> "\n")
      end
    end)
  end

  @doc false
  defp reparar_encabezado(ruta, encabezado) do
    {:ok, contenido} = File.read(ruta)

    # Elimina primera línea y agrega encabezado correcto
    [_ | filas] = String.split(contenido, "\n")

    nuevo_contenido =
      ([encabezado] ++ filas)
      |> Enum.join("\n")

    File.write!(ruta, nuevo_contenido)
  end

  @doc false
  defp encabezado_incorrecto?(ruta, encabezado_correcto) do
    case File.open(ruta, [:read]) do
      {:ok, file} ->
        primera_linea = IO.read(file, :line) |> String.trim()
        File.close(file)
        primera_linea != encabezado_correcto

      _ ->
        true
    end
  end

  @doc false
  defp ruta(nombre_archivo), do: Path.join(["data", nombre_archivo])
end
