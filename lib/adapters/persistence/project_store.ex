defmodule ProyectoFinalPrg3.Adapters.Persistence.ProjectStore do
  @moduledoc """
  Persistencia oficial de proyectos..
  Proporciona operaciones CRUD y consultas específicas.
  Autores: [Sharif Giraldo Obando, Juan Sebastián Hernández y Santiago Ospina Sánchez]
  Fecha de creación: 2025-11-16
  Fecha de última modificación: 2025-11-16
  Licencia: GNU GPL v3
  """

  alias ProyectoFinalPrg3.Domain.Project

  @ruta Path.join([File.cwd!(), "data", "proyectos.csv"])
  @headers "id,nombre,descripcion,categoria,estado,fecha_creacion,equipo_id,mentor_id,repositorio_url,puntaje\n"

  # ============================================================
  # CRUD
  # ============================================================

  @doc"""
  Guarda o actualiza un proyecto basado en su id o nombre.
  Parámetros:
    - `p`: Struct %Project{} a guardar o actualizar.
  Retorna:
    - `{:ok, p}` confirmando la operación.
  """
  def guardar_proyecto(%Project{} = p) do
    lista =
      listar_proyectos()
      |> Enum.reject(&(&1.id == p.id or &1.nombre == p.nombre))
      |> Kernel.++([p])

    persistir(lista)
    {:ok, p}
  end

  @doc"""
  Obtiene un proyecto por su id.
  Parámetros:
    - `id`: Identificador único del proyecto.
  Retorna:
    - El struct %Project{} si se encuentra, o nil si no.
  """
  def obtener_por_id(id) do
    listar_proyectos()
    |> Enum.find(&(&1.id == id))
  end

  @doc"""
  Obtiene un proyecto por su nombre.
  Parámetros:
    - `nombre`: Nombre único del proyecto.
  Retorna:
    - El struct %Project{} si se encuentra, o nil si no.
  """
  def obtener_proyecto(nombre) do
    listar_proyectos()
    |> Enum.find(&(&1.nombre == nombre))
  end

  @doc"""
  Lista todos los proyectos almacenados.
  Retorna:
    - Lista de structs %Project{}.
  """
  def listar_proyectos do
    if File.exists?(@ruta) do
      @ruta
      |> File.stream!()
      |> Stream.drop(1)
      |> Enum.map(&parse_line/1)
      |> Enum.reject(&is_nil/1)
    else
      []
    end
  end

  @doc"""
  Elimina un proyecto por su nombre.
  Parámetros:
    - `nombre`: Nombre único del proyecto a eliminar.
  Retorna:
    - `:ok` tras la eliminación.
  """
  def eliminar_proyecto(nombre) do
    nuevos =
      listar_proyectos()
      |> Enum.reject(&(&1.nombre == nombre))

    persistir(nuevos)
    :ok
  end

  # ============================================================
  # SERIALIZACIÓN
  # ============================================================

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
  defp to_csv(p) do
    [
      p.id,
      clean(p.nombre),
      clean(p.descripcion),
      p.categoria,
      Atom.to_string(p.estado),
      serialize_dt(p.fecha_creacion),
      p.equipo_id || "",
      p.mentor_id || "",
      p.repositorio_url || "",
      p.puntaje || ""
    ]
    |> Enum.join(",")
  end

  # ============================================================
  # PARSEO
  # ============================================================

  @doc false
  defp parse_line(line) do
    case String.split(String.trim(line), ",", parts: 10) do
      [id, nombre, descripcion, categoria, estado, fecha, equipo_id, mentor_id, repo, puntaje] ->
        %Project{
          id: id,
          nombre: nombre,
          descripcion: descripcion,
          categoria: categoria,
          estado: String.to_atom(estado),
          fecha_creacion: parse_dt(fecha),
          equipo_id: blank(equipo_id),
          mentor_id: blank(mentor_id),
          repositorio_url: blank(repo),
          puntaje: parse_int(puntaje)
        }

      _ ->
        # Línea inválida, ignorar
        nil
    end
  end

  # ============================================================
  # HELPERS
  # ============================================================

  @doc false
  defp clean(nil), do: ""
  defp clean(txt), do: txt |> String.replace(",", ";") |> String.replace("\n", " ")

  @doc false
  defp blank(""), do: nil
  defp blank(v), do: v

  @doc false
  defp parse_int(""), do: nil
  defp parse_int(v), do: String.to_integer(v)

  @doc false
  defp serialize_dt(nil), do: ""
  defp serialize_dt(%DateTime{} = dt), do: DateTime.to_iso8601(dt)

  @doc false
  defp parse_dt(""), do: nil
  defp parse_dt(str) do
    case DateTime.from_iso8601(str) do
      {:ok, dt, _} -> dt
      _ -> nil
    end
  end
end
