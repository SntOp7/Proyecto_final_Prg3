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

  Autores:
    Sharif Giraldo,
    Juan Sebastián Hernández,
    Santiago Ospina Sánchez

  Fecha: 2025-11-16
  Licencia: GNU GPLv3
  """

  alias ProyectoFinalPrg3.Adapters.Logging.LoggerService

  @csv_files [
    {:categorias,        "categorias.csv",
      "id,nombre,descripcion,proyectos,fecha_creacion,creador_id,activo"},

    {:feedback,          "feedback.csv",
      "id,mentor_id,proyecto_id,equipo_id,avance_id,contenido,fecha_creacion,nivel,visibilidad,estado"},

    {:mentores,          "mentores.csv",
      "id,nombre,correo,especialidad,biografia,equipos_asignados,disponibilidad,canal_mentoria_id,fecha_registro,retroalimentaciones,rol,activo"},

    {:participantes,     "participantes.csv",
      "id,nombre,correo,username,rol,equipo_id,experiencia,fecha_registro,estado,ultima_conexion,mensajes,canales_asignados,token_sesion,perfil_url"},

    {:progress,          "progress.csv",
      "id,proyecto_id,equipo_id,titulo,descripcion,fecha_registro,autor_id,estado,retroalimentacion,adjuntos,version"},

    {:proyectos,         "proyectos.csv",
      "id,nombre,descripcion,categoria,estado,fecha_creacion,fecha_actualizacion,equipo_id,mentor_id,avances,retroalimentaciones,repositorio_url,puntaje,visibilidad,tags"},

    {:equipos,           "equipos.csv",
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
  """
  def inicializar do
    crear_directorio_data()
    crear_archivos_csv()

    LoggerService.registrar_evento("Persistencia inicializada correctamente", %{
      tipo: :persistencia,
      fecha: DateTime.utc_now()
    })

    :ok
  end

  @doc """
  Verifica integridad de todos los archivos:

    - Existan
    - Tengan encabezados válidos

  Si encuentra algún archivo incorrecto, lo repara automáticamente.
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

  defp crear_directorio_data do
    File.mkdir_p!("data")
  end

  defp crear_archivos_csv do
    Enum.each(@csv_files, fn {_key, nombre_archivo, encabezado} ->
      ruta = ruta(nombre_archivo)

      if not File.exists?(ruta) do
        File.write!(ruta, encabezado <> "\n")
      end
    end)
  end

  defp reparar_encabezado(ruta, encabezado) do
    {:ok, contenido} = File.read(ruta)

    # Elimina primera línea y agrega encabezado correcto
    [_ | filas] = String.split(contenido, "\n")

    nuevo_contenido =
      ([encabezado] ++ filas)
      |> Enum.join("\n")

    File.write!(ruta, nuevo_contenido)
  end

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

  defp ruta(nombre_archivo), do: Path.join(["data", nombre_archivo])
end
