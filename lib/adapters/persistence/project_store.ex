defmodule ProyectoFinalPrg3.Adapters.Persistence.ProjectStore do
  @moduledoc """
  Persistencia oficial de proyectos.
  Compatible al 100% con el dominio Project reducido.
  """

  alias ProyectoFinalPrg3.Domain.Project

  @ruta Path.join([File.cwd!(), "data", "proyectos.csv"])
  @headers "id,nombre,descripcion,categoria,estado,fecha_creacion,equipo_id,mentor_id,repositorio_url,puntaje\n"

  # ============================================================
  # CRUD
  # ============================================================

  def guardar_proyecto(%Project{} = p) do
    lista =
      listar_proyectos()
      |> Enum.reject(&(&1.id == p.id or &1.nombre == p.nombre))
      |> Kernel.++([p])

    persistir(lista)
    {:ok, p}
  end

  def obtener_por_id(id) do
    listar_proyectos()
    |> Enum.find(&(&1.id == id))
  end

  def obtener_proyecto(nombre) do
    listar_proyectos()
    |> Enum.find(&(&1.nombre == nombre))
  end

  def listar_proyectos do
    if File.exists?(@ruta) do
      @ruta
      |> File.stream!()
      |> Stream.drop(1)
      |> Enum.map(&parse_line/1)
    else
      []
    end
  end

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

  defp persistir(lista) do
    File.mkdir_p!("data")

    contenido =
      lista
      |> Enum.map(&to_csv/1)
      |> Enum.join("\n")

    File.write!(@ruta, @headers <> contenido <> "\n")
  end

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

  defp parse_line(line) do
    [
      id,
      nombre,
      descripcion,
      categoria,
      estado,
      fecha,
      equipo_id,
      mentor_id,
      repo,
      puntaje
    ] = String.split(String.trim(line), ",", parts: 10)

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
  end

  # ============================================================
  # HELPERS
  # ============================================================

  defp clean(nil), do: ""
  defp clean(txt), do: txt |> String.replace(",", ";") |> String.replace("\n", " ")

  defp blank(""), do: nil
  defp blank(v), do: v

  defp parse_int(""), do: nil
  defp parse_int(v), do: String.to_integer(v)

  defp serialize_dt(nil), do: ""
  defp serialize_dt(%DateTime{} = dt), do: DateTime.to_iso8601(dt)

  defp parse_dt(""), do: nil
  defp parse_dt(str) do
    case DateTime.from_iso8601(str) do
      {:ok, dt, _} -> dt
      _ -> nil
    end
  end
end
