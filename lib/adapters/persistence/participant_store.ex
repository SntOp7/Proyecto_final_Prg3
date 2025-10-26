defmodule ProyectoFinalPrg3.Adapters.Persistence.ParticipantStore do
  @moduledoc """
  Módulo encargado de la persistencia de los participantes del sistema en archivos CSV.
  Administra las operaciones CRUD y convierte los datos entre estructuras `%Participant{}` y texto CSV.

  Este adaptador garantiza la independencia entre la capa de negocio y la persistencia.

  Autores: [Sharif Giraldo, Juan Sebastián Hernández y Santiago Ospina Sánchez]
  Fecha de creación: 2025-10-27
  Licencia: GNU GPLv3
  """

  alias ProyectoFinalPrg3.Domain.Participant

  @ruta_archivo Path.join([File.cwd!(), "data", "participantes.csv"])

  @headers """
  id,nombre,correo,username,rol,equipo_id,experiencia,fecha_registro,estado,ultima_conexion,mensajes,canales_asignados,token_sesion,perfil_url
  """ |> String.trim() <> "\n"

  # ============================================================
  # FUNCIONES PRINCIPALES CRUD
  # ============================================================

  @doc """
  Guarda o actualiza un participante en el archivo CSV.
  Si ya existe un participante con el mismo ID, se reemplaza.
  """
  def guardar_participante(%Participant{} = participante) do
    participantes =
      listar_participantes()
      |> Enum.reject(&(&1.id == participante.id))
      |> Kernel.++([participante])

    escribir_participantes(participantes)
    {:ok, participante}
  end

  @doc """
  Obtiene un participante a partir de su ID.
  """
  def obtener_participante(id) do
    listar_participantes()
    |> Enum.find(fn p -> p.id == id end)
  end

  @doc """
  Busca un participante por su correo electrónico.
  """
  def buscar_por_correo(correo) do
    listar_participantes()
    |> Enum.find(fn p -> p.correo == correo end)
  end

  @doc """
  Lista todos los participantes almacenados.
  """
  def listar_participantes do
    if File.exists?(@data_path) do
      File.stream!(@data_path)
      |> Stream.drop(1)
      |> Stream.map(&parse_csv_line/1)
      |> Enum.to_list()
    else
      []
    end
  end

  @doc """
  Elimina un participante por su ID.
  """
  def eliminar_participante(id) do
    participantes_filtrados =
      listar_participantes()
      |> Enum.reject(fn p -> p.id == id end)

    escribir_participantes(participantes_filtrados)
    :ok
  end

  # ============================================================
  # FUNCIONES DE SERIALIZACIÓN / DESERIALIZACIÓN
  # ============================================================

  defp parse_csv_line(line) do
    [
      id,
      nombre,
      correo,
      username,
      rol,
      equipo_id,
      experiencia,
      fecha_str,
      estado_str,
      ultima_conexion_str,
      mensajes_str,
      canales_str,
      token,
      perfil_url
    ] =
      line
      |> String.trim()
      |> String.split(",", parts: 14)

    %Participant{
      id: id,
      nombre: nombre,
      correo: correo,
      username: username,
      rol: rol,
      equipo_id: parse_nil(equipo_id),
      experiencia: experiencia,
      fecha_registro: parse_datetime(fecha_str),
      estado: parse_estado(estado_str),
      ultima_conexion: parse_datetime(ultima_conexion_str),
      mensajes: parse_json_list(mensajes_str),
      canales_asignados: parse_list(canales_str),
      token_sesion: parse_nil(token),
      perfil_url: parse_nil(perfil_url)
    }
  end

  defp escribir_participantes(participantes) do
    contenido =
      participantes
      |> Enum.map(&to_csv_line/1)
      |> Enum.join("\n")

    File.mkdir_p!("data")
    File.write!(@data_path, @headers <> contenido)
  end

  defp to_csv_line(%Participant{} = p) do
    [
      p.id,
      sanitize(p.nombre),
      p.correo,
      sanitize(p.username),
      p.rol,
      p.equipo_id || "",
      sanitize(p.experiencia || ""),
      serialize_datetime(p.fecha_registro),
      Atom.to_string(p.estado || :activo),
      serialize_datetime(p.ultima_conexion),
      serialize_json_list(p.mensajes),
      serialize_list(p.canales_asignados),
      p.token_sesion || "",
      p.perfil_url || ""
    ]
    |> Enum.join(",")
  end

  # ============================================================
  # FUNCIONES AUXILIARES DE FORMATEO
  # ============================================================

  defp sanitize(texto) when is_binary(texto) do
    texto
    |> String.replace(",", ";")
    |> String.replace("\n", " ")
  end

  defp parse_nil(""), do: nil
  defp parse_nil(valor), do: valor

  defp parse_estado("activo"), do: :activo
  defp parse_estado("pendiente"), do: :pendiente
  defp parse_estado("desconectado"), do: :desconectado
  defp parse_estado(_), do: :activo

  # Manejo de fechas y tiempos
  defp parse_datetime(""), do: nil
  defp parse_datetime(str) do
    case DateTime.from_iso8601(str) do
      {:ok, dt, _} -> dt
      _ -> nil
    end
  end

  defp serialize_datetime(nil), do: ""
  defp serialize_datetime(%DateTime{} = dt), do: DateTime.to_iso8601(dt)

  # Manejo de listas simples (ej. canales)
  defp parse_list(""), do: []
  defp parse_list(str), do: String.split(str, ";")

  defp serialize_list(lista) when is_list(lista), do: Enum.join(lista, ";")
  defp serialize_list(_), do: ""

  # Manejo de listas complejas (mensajes)
  defp parse_json_list(""), do: []
  defp parse_json_list(str) do
    str
    |> String.split("|")
    |> Enum.map(fn item ->
      case String.split(item, "~", parts: 2) do
        [msg, timestamp] -> %{mensaje: msg, timestamp: parse_datetime(timestamp)}
        [msg] -> %{mensaje: msg, timestamp: nil}
      end
    end)
  end

  defp serialize_json_list(lista) when is_list(lista) do
    lista
    |> Enum.map(fn %{mensaje: msg, timestamp: ts} ->
      "#{sanitize(msg)}~#{serialize_datetime(ts)}"
    end)
    |> Enum.join("|")
  end

  defp serialize_json_list(_), do: ""
end
