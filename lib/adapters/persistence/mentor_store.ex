defmodule ProyectoFinalPrg3.Adapters.Persistence.MentorStore do
  @moduledoc """
  Módulo responsable de la persistencia de mentores en el sistema.
  Gestiona la lectura y escritura de datos en el archivo CSV `data/mentors.csv`,
  sirviendo como adaptador de la capa de persistencia dentro de la arquitectura hexagonal.

  Cada registro contiene la información completa de un mentor, incluyendo su especialidad,
  equipos asignados, disponibilidad, y retroalimentaciones.

  Autores: [Sharif Giraldo, Juan Sebastián Hernández y Santiago Ospina Sánchez]
  Fecha de creación: 2025-10-27
  Licencia: GNU GPLv3
  """

  alias ProyectoFinalPrg3.Domain.Mentor

  @ruta_archivo Path.join([File.cwd!(), "data", "mentores.csv"])
  @headers "id,nombre,correo,especialidad,biografia,equipos_asignados,disponibilidad,canal_mentoria_id,fecha_registro,retroalimentaciones,rol,activo\n"

  # ============================================================
  # FUNCIONES CRUD PRINCIPALES
  # ============================================================

  @doc """
  Guarda o actualiza un mentor en el archivo CSV.
  Si el mentor ya existe, su información se reemplaza.
  """
  def guardar_mentor(%Mentor{} = mentor) do
    mentores =
      listar_mentores()
      |> Enum.reject(&(&1.id == mentor.id))
      |> Kernel.++([mentor])

    escribir_mentores(mentores)
    {:ok, mentor}
  end

  @doc """
  Obtiene un mentor por su identificador único.
  Retorna `nil` si no existe.
  """
  def obtener_por_id(id) do
    listar_mentores()
    |> Enum.find(fn m -> m.id == id end)
  end

  @doc """
  Busca un mentor por su nombre.
  """
  def obtener_por_nombre(nombre) do
    listar_mentores()
    |> Enum.find(fn m -> m.nombre == nombre end)
  end

  @doc """
  Busca un mentor por su correo electrónico.
  """
  def buscar_por_correo(correo) do
    listar_mentores()
    |> Enum.find(fn m -> m.correo == correo end)
  end

  @doc """
  Lista todos los mentores registrados en el archivo CSV.
  """
  def listar_mentores do
    if File.exists?(@ruta_archivo) do
      File.stream!(@ruta_archivo)
      |> Stream.drop(1)
      |> Stream.map(&parse_csv_line/1)
      |> Enum.to_list()
    else
      []
    end
  end

  @doc """
  Elimina un mentor del sistema a partir de su ID.
  """
  def eliminar_mentor(id) do
    mentores_filtrados =
      listar_mentores()
      |> Enum.reject(fn m -> m.id == id end)

    escribir_mentores(mentores_filtrados)
    :ok
  end

  # ============================================================
  # FUNCIONES PRIVADAS DE SERIALIZACIÓN Y DESERIALIZACIÓN
  # ============================================================

  # Convierte una línea del CSV en una estructura %Mentor{}
  defp parse_csv_line(line) do
    [
      id,
      nombre,
      correo,
      especialidad,
      biografia,
      equipos_asignados,
      disponibilidad,
      canal_mentoria_id,
      fecha_registro,
      retroalimentaciones,
      rol,
      activo
    ] =
      line
      |> String.trim()
      |> String.split(",", parts: 12)

    %Mentor{
      id: id,
      nombre: nombre,
      correo: correo,
      especialidad: especialidad,
      biografia: biografia,
      equipos_asignados: parse_list(equipos_asignados),
      disponibilidad: parse_atom(disponibilidad, :desconectado),
      canal_mentoria_id: parse_nil(canal_mentoria_id),
      fecha_registro: parse_datetime(fecha_registro),
      retroalimentaciones: parse_list(retroalimentaciones),
      rol: rol,
      activo: parse_bool(activo)
    }
  end

  # Escribe la lista completa de mentores al archivo CSV
  defp escribir_mentores(mentores) do
    contenido =
      mentores
      |> Enum.map(&to_csv_line/1)
      |> Enum.join("\n")

    File.mkdir_p!("data")
    File.write!(@ruta_archivo, @headers <> contenido)
  end

  # Convierte un mentor en una línea CSV
  defp to_csv_line(%Mentor{} = m) do
    [
      m.id,
      sanitize(m.nombre),
      m.correo,
      sanitize(m.especialidad),
      sanitize(m.biografia),
      Enum.join(m.equipos_asignados || [], ";"),
      Atom.to_string(m.disponibilidad),
      m.canal_mentoria_id || "",
      format_datetime(m.fecha_registro),
      Enum.join(m.retroalimentaciones || [], ";"),
      m.rol,
      to_string(m.activo)
    ]
    |> Enum.join(",")
  end

  # ============================================================
  # FUNCIONES AUXILIARES
  # ============================================================

  defp sanitize(texto) when is_binary(texto) do
    texto
    |> String.replace(",", ";")
    |> String.replace("\n", " ")
  end

  defp parse_nil(""), do: nil
  defp parse_nil(valor), do: valor

  defp parse_bool("true"), do: true
  defp parse_bool("false"), do: false
  defp parse_bool(_), do: false

  defp parse_list(""), do: []
  defp parse_list(cadena), do: String.split(cadena, ";")

  defp parse_atom("", default), do: default
  defp parse_atom(str, _), do: String.to_atom(str)

  defp parse_datetime(""), do: nil
  defp parse_datetime(str) do
    case DateTime.from_iso8601(str) do
      {:ok, dt, _} -> dt
      _ -> nil
    end
  end

  defp format_datetime(nil), do: ""
  defp format_datetime(%DateTime{} = dt), do: DateTime.to_iso8601(dt)
end
