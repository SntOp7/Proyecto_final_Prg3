defmodule ProyectoFinalPrg3.Adapters.Persistence.MentorStore do
  @moduledoc """
  Módulo de persistencia responsable de almacenar, leer, actualizar y eliminar
  los mentores registrados en el sistema de hackathon.

  Este adaptador pertenece a la capa de persistencia de la arquitectura hexagonal
  y es utilizado directamente por el servicio `MentorManager`.

  Los datos se almacenan en el archivo `data/mentors.csv`, con soporte de
  serialización JSON para listas de equipos y proyectos asignados.

  Autores: [Sharif Giraldo, Juan Sebastián Hernández y Santiago Ospina Sánchez]
  Fecha de creación: 2025-10-26
  Licencia: GNU GPLv3
  """

  alias ProyectoFinalPrg3.Domain.Mentor
  @ruta_archivo Path.join([File.cwd!(), "data", "mentors.csv"])

  # ============================================================
  # FUNCIONES PÚBLICAS PRINCIPALES
  # ============================================================

  @doc """
  Guarda un nuevo mentor o actualiza uno existente en el archivo CSV.
  """
  def guardar_mentor(%Mentor{} = mentor) do
    mentores = listar_mentores()

    mentores_actualizados =
      mentores
      |> Enum.reject(&(&1.id == mentor.id))
      |> Kernel.++([mentor])

    persistir_lista(mentores_actualizados)
  end

  @doc """
  Devuelve la lista completa de mentores registrados.
  """
  def listar_mentores do
    if File.exists?(@data_file) do
      File.stream!(@data_file)
      |> Stream.map(&String.trim/1)
      |> Stream.reject(&(&1 == ""))
      |> Enum.map(&parsear_linea/1)
    else
      []
    end
  end

  @doc """
  Obtiene un mentor a partir de su ID único.
  """
  def obtener_por_id(id) do
    listar_mentores()
    |> Enum.find(&(&1.id == id))
  end

  @doc """
  Obtiene un mentor por su nombre.
  """
  def obtener_por_nombre(nombre) do
    listar_mentores()
    |> Enum.find(&(&1.nombre == nombre))
  end

  @doc """
  Elimina un mentor del sistema por su ID.
  """
  def eliminar_mentor(id) do
    mentores =
      listar_mentores()
      |> Enum.reject(&(&1.id == id))

    persistir_lista(mentores)
  end

  # ============================================================
  # FUNCIONES INTERNAS DE PERSISTENCIA
  # ============================================================

  @doc false
  defp persistir_lista(lista_mentores) do
    File.mkdir_p!("data")

    contenido =
      lista_mentores
      |> Enum.map(&serializar_mentor/1)
      |> Enum.join("\n")

    File.write!(@data_file, contenido)
  end

  @doc false
  defp serializar_mentor(%Mentor{} = mentor) do
    [
      mentor.id,
      limpiar(mentor.nombre),
      limpiar(mentor.especialidad),
      limpiar(mentor.experiencia),
      serialize_json(mentor.equipos_asignados),
      serialize_json(mentor.proyectos_asignados),
      serialize_timestamp(mentor.fecha_registro),
      Atom.to_string(mentor.estado)
    ]
    |> Enum.join(",")
  end

  @doc false
  defp parsear_linea(linea) do
    [
      id,
      nombre,
      especialidad,
      experiencia,
      equipos_json,
      proyectos_json,
      fecha_registro,
      estado
    ] =
      String.split(linea, ",", parts: 8)

    %Mentor{
      id: id,
      nombre: nombre,
      especialidad: especialidad,
      experiencia: experiencia,
      equipos_asignados: parse_json(equipos_json),
      proyectos_asignados: parse_json(proyectos_json),
      fecha_registro: parse_timestamp(fecha_registro),
      estado: String.to_atom(estado)
    }
  end

  # ============================================================
  # FUNCIONES AUXILIARES DE SERIALIZACIÓN
  # ============================================================

  @doc false
  defp limpiar(nil), do: ""
  defp limpiar(texto), do: texto |> String.replace(",", ";") |> String.trim()

  @doc false
  defp serialize_timestamp(nil), do: ""
  defp serialize_timestamp(%DateTime{} = dt), do: DateTime.to_iso8601(dt)

  @doc false
  defp parse_timestamp(""), do: nil
  defp parse_timestamp(valor) do
    case DateTime.from_iso8601(valor) do
      {:ok, dt, _} -> dt
      _ -> nil
    end
  end

  @doc false
  defp serialize_json(nil), do: "[]"
  defp serialize_json(lista) when is_list(lista), do: Jason.encode!(lista)

  @doc false
  defp parse_json(""), do: []
  defp parse_json(json) do
    case Jason.decode(json) do
      {:ok, lista} -> lista
      _ -> []
    end
  end
end
