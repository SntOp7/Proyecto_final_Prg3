defmodule ProyectoFinalPrg3.Adapters.Persistence.TeamStore do
  @moduledoc """
  Módulo responsable de la persistencia de datos de los equipos en el sistema.
  Implementa operaciones CRUD sobre un archivo CSV ubicado en la carpeta `data/teams.csv`.

  Este adaptador actúa como interfaz entre la capa de servicios (`TeamManager`)
  y el almacenamiento físico, asegurando la independencia de la lógica de negocio.

  Autores: [Sharif Giraldo, Juan Sebastián Hernández y Santiago Ospina Sánchez]
  Fecha de creación: 2025-10-25
  Licencia: GNU GPLv3
  """

  alias ProyectoFinalPrg3.Domain.Team

  @ruta_archivo Path.join([File.cwd!(), "data", "equipos.csv"])
  @headers "id,nombre,descripcion,categoria,id_proyecto,id_mentor,participantes,fecha_creacion,estado,canal_chat_id,puntaje,historial\n"

  # ============================================================
  # FUNCIONES PÚBLICAS CRUD
  # ============================================================

  @doc """
  Guarda un equipo nuevo o actualiza uno existente en el archivo CSV.
  Si el archivo no existe, lo crea automáticamente.
  """
  def guardar_equipo(equipo = %Team{}) do
    equipos = listar_equipos()

    equipos_actualizados =
      equipos
      |> Enum.reject(&(&1.id == equipo.id))
      |> Kernel.++([equipo])

    escribir_equipos(equipos_actualizados)
    {:ok, equipo}
  end

  @doc """
  Obtiene un equipo a partir de su nombre.
  Retorna `nil` si no se encuentra.
  """
  def obtener_equipo(nombre) do
    listar_equipos()
    |> Enum.find(fn eq -> eq.nombre == nombre end)
  end

  @doc """
  Lista todos los equipos registrados en el archivo CSV.
  """
  def listar_equipos do
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
  Elimina un equipo del registro a partir de su nombre.
  """
  def eliminar_equipo(nombre) do
    equipos_filtrados =
      listar_equipos()
      |> Enum.reject(fn eq -> eq.nombre == nombre end)

    escribir_equipos(equipos_filtrados)
    :ok
  end

  # ============================================================
  # FUNCIONES PRIVADAS DE SERIALIZACIÓN
  # ============================================================

  # Convierte una línea CSV a una estructura %Team{}
  defp parse_csv_line(line) do
    [id, nombre, descripcion, categoria, id_proyecto, id_mentor, participantes_str,
     fecha_str, estado_str, canal_chat_id, puntaje_str, historial_str] =
      line
      |> String.trim()
      |> String.split(",", parts: 12)

    %Team{
      id: id,
      nombre: nombre,
      descripcion: descripcion,
      categoria: categoria,
      id_proyecto: parse_nil(id_proyecto),
      id_mentor: parse_nil(id_mentor),
      participantes: parse_list(participantes_str),
      fecha_creacion: parse_datetime(fecha_str),
      estado: parse_estado(estado_str),
      canal_chat_id: parse_nil(canal_chat_id),
      puntaje: String.to_integer(puntaje_str || "0"),
      historial: parse_historial(historial_str)
    }
  end

  # Convierte lista de %Team{} a CSV y guarda el archivo
  defp escribir_equipos(equipos) do
    contenido =
      equipos
      |> Enum.map(&to_csv_line/1)
      |> Enum.join("\n")

    File.mkdir_p!("data")
    File.write!(@data_path, @headers <> contenido)
  end

  # Convierte un equipo a una línea CSV
  defp to_csv_line(%Team{} = eq) do
    [
      eq.id,
      eq.nombre,
      sanitize(eq.descripcion),
      eq.categoria,
      eq.id_proyecto || "",
      eq.id_mentor || "",
      serialize_list(eq.participantes),
      serialize_datetime(eq.fecha_creacion),
      Atom.to_string(eq.estado),
      eq.canal_chat_id || "",
      Integer.to_string(eq.puntaje),
      serialize_historial(eq.historial)
    ]
    |> Enum.join(",")
  end

  # ============================================================
  # FUNCIONES AUXILIARES DE SERIALIZACIÓN/DESERIALIZACIÓN
  # ============================================================

  defp sanitize(texto) when is_binary(texto) do
    texto
    |> String.replace(",", ";")
    |> String.replace("\n", " ")
  end

  defp parse_nil(""), do: nil
  defp parse_nil(valor), do: valor

  defp parse_datetime(""), do: nil
  defp parse_datetime(str), do: DateTime.from_iso8601(str) |> elem(1)

  defp serialize_datetime(nil), do: ""
  defp serialize_datetime(dt), do: DateTime.to_iso8601(dt)

  defp parse_estado("activo"), do: :activo
  defp parse_estado("inactivo"), do: :inactivo
  defp parse_estado(_), do: :activo

  defp parse_list(""), do: []
  defp parse_list(str), do: String.split(str, ";")

  defp serialize_list(lista) when is_list(lista), do: Enum.join(lista, ";")
  defp serialize_list(_), do: ""

  defp parse_historial(""), do: []
  defp parse_historial(str) do
    str
    |> String.split("|")
    |> Enum.map(fn e -> %{timestamp: nil, detalle: e} end)
  end

  defp serialize_historial(historial) when is_list(historial) do
    historial
    |> Enum.map(fn %{detalle: d} -> sanitize(d) end)
    |> Enum.join("|")
  end

  defp serialize_historial(_), do: ""
end
