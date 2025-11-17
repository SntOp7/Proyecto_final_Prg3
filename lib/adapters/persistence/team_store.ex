defmodule ProyectoFinalPrg3.Adapters.Persistence.TeamStore do
  @moduledoc """
  Persistencia oficial de equipos (Team).
  Alineado al dominio Team (id, nombre, descripcion, categoria, id_proyecto, id_mentor, participantes, fecha_creacion, estado).
  Proporciona funciones para guardar, obtener, listar y eliminar equipos.
  Autores: [Sharif Giraldo Obando, Juan Sebastián Hernández y Santiago Ospina Sánchez]
  Fecha de creación: 2025-11-16
  Fecha de última modificación: 2025-11-16
  Licencia: GNU GPL v3
  """

  alias ProyectoFinalPrg3.Domain.Team

  @ruta Path.join([File.cwd!(), "data", "equipos.csv"])

  @headers "id,nombre,descripcion,categoria,id_proyecto,id_mentor,participantes,fecha_creacion,estado\n"

  # -------------------------------------------------------------
  # CRUD
  # -------------------------------------------------------------

  @doc"""
  Función para guardar o actualizar un equipo.
  Parámetros:
    - `equipo`: Struct %Team{} a guardar o actualizar.
  Retorna:
    - `{:ok, equipo}` confirmando la operación.
  """
  def guardar_equipo(%Team{} = equipo) do
    lista =
      listar_equipos()
      |> Enum.reject(&(&1.id == equipo.id))
      |> Kernel.++([equipo])

    persistir(lista)
    {:ok, equipo}
  end

  @doc"""
  Obtiene un equipo por su nombre.
  Parámetros:
    - `nombre`: Nombre único del equipo.
  Retorna:
    - El struct %Team{} si se encuentra, o nil si no.
  """
  def obtener_equipo(nombre) do
    listar_equipos()
    |> Enum.find(&(&1.nombre == nombre))
  end

  @doc"""
  Obtiene un equipo por su ID.
  Parámetros:
    - `id`: ID único del equipo.
  Retorna:
    - El struct %Team{} si se encuentra, o nil si no.
  """
  def obtener_equipo_por_id(id) do
    listar_equipos()
    |> Enum.find(&(&1.id == id))
  end

  @doc"""
  Lista todos los equipos almacenados.
  Retorna:
    - Una lista de structs %Team{}.
  """
  def listar_equipos do
    if File.exists?(@ruta) do
      @ruta
      |> File.stream!()
      |> Stream.drop(1)
      |> Enum.map(&parse_line/1)
    else
      []
    end
  end

  @doc"""
  Elimina un equipo por su nombre.
  Parámetros:
    - `nombre`: Nombre único del equipo.
  Retorna:
    - `:ok` tras la eliminación.
  """
  def eliminar_equipo(nombre) do
    nuevos =
      listar_equipos()
      |> Enum.reject(&(&1.nombre == nombre))

    persistir(nuevos)
    :ok
  end

  # -------------------------------------------------------------
  # Serialización
  # -------------------------------------------------------------

  @doc false
  defp persistir(lista) do
    File.mkdir_p!("data")

    contenido =
      lista
      |> Enum.map(&to_csv/1)
      |> Enum.join("\n")

    File.write!(@ruta, @headers <> contenido <> "\n")
  end

  @doc false
  defp to_csv(t) do
    [
      t.id,
      clean(t.nombre),
      clean(t.descripcion),
      t.categoria,
      t.id_proyecto || "",
      t.id_mentor || "",
      serialize_list(t.participantes),
      serialize_dt(t.fecha_creacion),
      Atom.to_string(t.estado)
    ]
    |> Enum.join(",")
  end

  # -------------------------------------------------------------
  # Parseo
  # -------------------------------------------------------------

  @doc false
  defp parse_line(line) do
    [
      id,
      nombre,
      descripcion,
      categoria,
      id_proyecto,
      id_mentor,
      participantes,
      fecha,
      estado
    ] = String.split(String.trim(line), ",", parts: 9)

    %Team{
      id: id,
      nombre: nombre,
      descripcion: descripcion,
      categoria: categoria,
      id_proyecto: blank(id_proyecto),
      id_mentor: blank(id_mentor),
      participantes: parse_list(participantes),
      fecha_creacion: parse_dt(fecha),
      estado: String.to_atom(estado)
    }
  end

  # -------------------------------------------------------------
  # Utilidades
  # -------------------------------------------------------------

  @doc false
  defp clean(nil), do: ""

  @doc false
  defp clean(txt), do: txt |> String.replace(",", ";") |> String.replace("\n", " ")

  @doc false
  defp blank(""), do: nil

  @doc false
  defp blank(v), do: v

  @doc false
  defp serialize_dt(nil), do: ""

  @doc false
  defp serialize_dt(%DateTime{} = dt), do: DateTime.to_iso8601(dt)

  @doc false
  defp parse_dt(""), do: nil

  @doc false
  defp parse_dt(str) do
    case DateTime.from_iso8601(str) do
      {:ok, dt, _} -> dt
      _ -> nil
    end
  end

  @doc false
  defp serialize_list(list) when is_list(list), do: Enum.join(list, ";")

  @doc false
  defp serialize_list(_), do: ""

  @doc false
  defp parse_list(""), do: []

  @doc false
  defp parse_list(str), do: String.split(str, ";")
end
