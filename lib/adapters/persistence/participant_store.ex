defmodule ProyectoFinalPrg3.Adapters.Persistence.ParticipantStore do
  @moduledoc """
  Persistencia de participantes alineada al dominio Participant.

  Guarda únicamente los campos definidos en la estructura oficial:

  id, nombre, correo, username, contrasena, rol, equipo_id, estado, mensajes
  """

  alias ProyectoFinalPrg3.Domain.Participant

  @ruta Path.join([File.cwd!(), "data", "participantes.csv"])

  @headers "id,nombre,correo,username,contrasena,rol,equipo_id,estado,mensajes\n"

  # ============================================================
  # CRUD PRINCIPAL
  # ============================================================

  def guardar_participante(%Participant{} = p) do
    lista =
      listar_participantes()
      |> Enum.reject(&(&1.id == p.id))
      |> Kernel.++([p])

    escribir(lista)
    {:ok, p}
  end

  def obtener_participante(id) do
    listar_participantes()
    |> Enum.find(&(&1.id == id))
  end

  def buscar_por_correo(correo) do
    listar_participantes()
    |> Enum.find(&(&1.correo == correo))
  end

  def eliminar_participante(id) do
    nuevos =
      listar_participantes()
      |> Enum.reject(&(&1.id == id))

    escribir(nuevos)
    :ok
  end

  def listar_participantes do
    if File.exists?(@ruta) do
      File.stream!(@ruta)
      |> Stream.drop(1)
      |> Stream.map(&parse_line/1)
      |> Enum.to_list()
    else
      []
    end
  rescue
    _ -> []
  end

  # ============================================================
  # SERIALIZACIÓN
  # ============================================================

  defp parse_line(line) do
    [
      id,
      nombre,
      correo,
      username,
      contrasena,
      rol,
      equipo_id,
      estado,
      mensajes_str
    ] =
      line
      |> String.trim()
      |> String.split(",", parts: 9)

    %Participant{
      id: id,
      nombre: nombre,
      correo: correo,
      username: username,
      contrasena: contrasena,
      rol: String.to_atom(rol),
      equipo_id: parse_nil(equipo_id),
      estado: String.to_atom(estado),
      mensajes: parse_mensajes(mensajes_str)
    }
  end

  defp escribir(lista) do
    contenido =
      lista
      |> Enum.map(&to_csv/1)
      |> Enum.join("\n")

    File.mkdir_p!("data")
    File.write!(@ruta, @headers <> contenido <> "\n")
  end

  defp to_csv(%Participant{} = p) do
    [
      p.id,
      sanitize(p.nombre),
      p.correo,
      sanitize(p.username),
      p.contrasena,
      Atom.to_string(p.rol),
      p.equipo_id || "",
      Atom.to_string(p.estado),
      serialize_mensajes(p.mensajes)
    ]
    |> Enum.join(",")
  end

  # ============================================================
  # UTILIDADES
  # ============================================================

  defp sanitize(text), do: text |> String.replace(",", ";") |> String.replace("\n", " ")

  defp parse_nil(""), do: nil
  defp parse_nil(v), do: v

  # mensajes almacenados como texto simple "msg1|msg2|msg3"
  defp parse_mensajes(""), do: []
  defp parse_mensajes(str), do: String.split(str, "|")

  defp serialize_mensajes(lista) when is_list(lista), do: Enum.join(lista, "|")
end
