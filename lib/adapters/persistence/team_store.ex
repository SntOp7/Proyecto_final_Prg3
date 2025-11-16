defmodule ProyectoFinalPrg3.Adapters.Persistence.TeamStore do
  @moduledoc """
  Persistencia oficial de equipos (Team).
  Totalmente compatible con el dominio reducido Team.
  """

  alias ProyectoFinalPrg3.Domain.Team

  @ruta Path.join([File.cwd!(), "data", "equipos.csv"])

  @headers "id,nombre,descripcion,categoria,id_proyecto,id_mentor,participantes,fecha_creacion,estado\n"

  # -------------------------------------------------------------
  # CRUD
  # -------------------------------------------------------------

  def guardar_equipo(%Team{} = equipo) do
    lista =
      listar_equipos()
      |> Enum.reject(&(&1.id == equipo.id))
      |> Kernel.++([equipo])

    persistir(lista)
    {:ok, equipo}
  end

  def obtener_equipo(nombre) do
    listar_equipos()
    |> Enum.find(&(&1.nombre == nombre))
  end

  def obtener_equipo_por_id(id) do
    listar_equipos()
    |> Enum.find(&(&1.id == id))
  end

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

  defp persistir(lista) do
    File.mkdir_p!("data")

    contenido =
      lista
      |> Enum.map(&to_csv/1)
      |> Enum.join("\n")

    File.write!(@ruta, @headers <> contenido <> "\n")
  end

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

  defp clean(nil), do: ""
  defp clean(txt), do: txt |> String.replace(",", ";") |> String.replace("\n", " ")

  defp blank(""), do: nil
  defp blank(v), do: v

  defp serialize_dt(nil), do: ""
  defp serialize_dt(%DateTime{} = dt), do: DateTime.to_iso8601(dt)

  defp parse_dt(""), do: nil
  defp parse_dt(str) do
    case DateTime.from_iso8601(str) do
      {:ok, dt, _} -> dt
      _ -> nil
    end
  end

  defp serialize_list(list) when is_list(list), do: Enum.join(list, ";")
  defp serialize_list(_), do: ""

  defp parse_list(""), do: []
  defp parse_list(str), do: String.split(str, ";")
end
