defmodule ProyectoFinalPrg3.Adapters.Persistence.ProjectStore do
  @moduledoc """
  Adaptador de persistencia responsable de almacenar y recuperar proyectos
  desde archivos CSV dentro del sistema de hackathon.

  Provee operaciones CRUD (crear, leer, actualizar y eliminar) y utilidades
  para filtrar o listar proyectos en memoria.

  Los archivos CSV se guardan en `data/projects.csv`.

  Autores: [Sharif Giraldo, Juan Sebastián Hernández y Santiago Ospina Sánchez]
  Fecha de creación: 2025-10-27
  Licencia: GNU GPLv3
  """

  alias ProyectoFinalPrg3.Domain.Project
  @data_path "data/projects.csv"

  # ============================================================
  # API PÚBLICA
  # ============================================================

  @doc """
  Guarda o actualiza un proyecto en el archivo CSV.
  Si el proyecto ya existe (por nombre o ID), se sobrescribe.
  """
  def guardar_proyecto(%Project{} = proyecto) do
    proyectos = listar_proyectos()
    proyectos_actualizados =
      proyectos
      |> Enum.reject(&(&1.id == proyecto.id or &1.nombre == proyecto.nombre))
      |> Kernel.++([proyecto])

    escribir_csv(proyectos_actualizados)
    :ok
  end

  @doc """
  Obtiene un proyecto por su nombre.
  """
  def obtener_proyecto(nombre) do
    listar_proyectos()
    |> Enum.find(&(&1.nombre == nombre))
  end

  @doc """
  Obtiene un proyecto por su ID.
  """
  def obtener_por_id(id) do
    listar_proyectos()
    |> Enum.find(&(&1.id == id))
  end

  @doc """
  Lista todos los proyectos almacenados.
  """
  def listar_proyectos do
    if File.exists?(@data_path) do
      @data_path
      |> File.stream!()
      |> CSV.decode!(headers: true)
      |> Enum.map(&mapear_a_struct/1)
    else
      []
    end
  end

  @doc """
  Elimina un proyecto por nombre del archivo CSV.
  """
  def eliminar_proyecto(nombre) do
    proyectos_restantes =
      listar_proyectos()
      |> Enum.reject(&(&1.nombre == nombre))

    escribir_csv(proyectos_restantes)
    :ok
  end

  # ============================================================
  # FUNCIONES PRIVADAS DE UTILIDAD
  # ============================================================

  defp escribir_csv(proyectos) do
    File.mkdir_p!("data")

    encabezados = [
      "id", "nombre", "descripcion", "categoria", "estado",
      "fecha_creacion", "fecha_actualizacion", "equipo_id", "mentor_id",
      "avances", "retroalimentaciones", "repositorio_url", "puntaje",
      "visibilidad", "tags"
    ]

    File.open!(@data_path, [:write], fn file ->
      IO.write(file, Enum.join(encabezados, ",") <> "\n")

      Enum.each(proyectos, fn p ->
        IO.write(file, a_csv_row(p))
      end)
    end)
  end

  defp a_csv_row(p) do
    [
      p.id,
      escape_csv(p.nombre),
      escape_csv(p.descripcion),
      p.categoria,
      Atom.to_string(p.estado),
      p.fecha_creacion,
      p.fecha_actualizacion,
      p.equipo_id,
      p.mentor_id,
      Enum.join(p.avances, "|"),
      Enum.join(p.retroalimentaciones, "|"),
      p.repositorio_url,
      p.puntaje,
      Atom.to_string(p.visibilidad),
      Enum.join(p.tags, "|")
    ]
    |> Enum.map(&to_string/1)
    |> Enum.join(",")
    |> Kernel.<>("\n")
  end

  defp mapear_a_struct(row) do
    %Project{
      id: row["id"],
      nombre: row["nombre"],
      descripcion: row["descripcion"],
      categoria: row["categoria"],
      estado: parse_atom(row["estado"]),
      fecha_creacion: parse_datetime(row["fecha_creacion"]),
      fecha_actualizacion: parse_datetime(row["fecha_actualizacion"]),
      equipo_id: nilify(row["equipo_id"]),
      mentor_id: nilify(row["mentor_id"]),
      avances: parse_list(row["avances"]),
      retroalimentaciones: parse_list(row["retroalimentaciones"]),
      repositorio_url: row["repositorio_url"],
      puntaje: parse_integer(row["puntaje"]),
      visibilidad: parse_atom(row["visibilidad"]),
      tags: parse_list(row["tags"])
    }
  end

  # ============================================================
  # PARSERS Y HELPERS
  # ============================================================

  defp escape_csv(value) when is_binary(value),
    do: "\"" <> String.replace(value, "\"", "'") <> "\""
  defp escape_csv(nil), do: ""
  defp escape_csv(value), do: to_string(value)

  defp parse_list(nil), do: []
  defp parse_list(""), do: []
  defp parse_list(str), do: String.split(str, "|", trim: true)

  defp parse_integer(nil), do: 0
  defp parse_integer(""), do: 0
  defp parse_integer(value), do: String.to_integer(value)

  defp parse_atom(nil), do: :desconocido
  defp parse_atom(""), do: :desconocido
  defp parse_atom(value) when is_binary(value), do: String.to_atom(value)
  defp parse_atom(value), do: value

  defp parse_datetime(nil), do: nil
  defp parse_datetime(""), do: nil
  defp parse_datetime(str), do: DateTime.from_iso8601(str) |> elem(1)

  defp nilify(""), do: nil
  defp nilify(nil), do: nil
  defp nilify(value), do: value
end
