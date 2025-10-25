defmodule ProyectoFinalPrg3.Adapters.Persistence.TeamStore do
  @moduledoc """
  Implementa la capa de persistencia para los equipos del sistema de hackathon.
  Este módulo gestiona las operaciones de lectura y escritura en un archivo CSV,
  garantizando el almacenamiento, actualización y eliminación de la información
  de los equipos registrados en el sistema.

  Autores: [Sharif Giraldo, Juan Sebastián Hernández y Santiago Ospina Sánchez]
  Fecha de creación: 2025-10-26
  Fecha de última modificación:
  Licencia: GNU GPLv3
  """

  alias ProyectoFinalPrg3.Domain.Team

  @ruta_archivo Path.join([File.cwd!(), "data", "equipos.csv"])

  @doc """
  Guarda un nuevo equipo o actualiza uno existente en el archivo CSV.
  Si el equipo ya existe (por nombre), su registro es reemplazado.
  """
  def guardar_equipo(equipo = %Team{}) do
    equipos = listar_equipos()

    equipos_actualizados =
      equipos
      |> Enum.reject(&(&1.nombre == equipo.nombre))
      |> Enum.concat([equipo])

    persistir_en_csv(equipos_actualizados)
    {:ok, equipo}
  end

  @doc """
  Obtiene un equipo del archivo CSV a partir de su nombre.
  Retorna `{:ok, team}` si existe o `nil` si no se encuentra.
  """
  def obtener_equipo(nombre) do
    equipos = listar_equipos()

    case Enum.find(equipos, &(&1.nombre == nombre)) do
      nil -> nil
      equipo -> {:ok, equipo}
    end
  end

  @doc """
  Lista todos los equipos almacenados en el archivo CSV.
  Retorna una lista de estructuras `%Team{}`.
  """
  def listar_equipos do
    case File.read(@ruta_archivo) do
      {:ok, contenido} ->
        contenido
        |> String.split("\n", trim: true)
        # omitir encabezado
        |> Enum.drop(1)
        |> Enum.map(&parsear_linea_a_struct/1)

      {:error, :enoent} ->
        # Si el archivo no existe, retornar lista vacía
        []
    end
  end

  @doc """
  Elimina un equipo del archivo CSV utilizando su nombre como identificador.
  Retorna `:ok` si se completa correctamente.
  """
  def eliminar_equipo(nombre) do
    equipos =
      listar_equipos()
      |> Enum.reject(&(&1.nombre == nombre))

    persistir_en_csv(equipos)
    :ok
  end

  # ============================================================
  # FUNCIONES INTERNAS DE APOYO
  # ============================================================

  @doc false
  defp persistir_en_csv(equipos) do
    encabezado =
      "id,nombre,descripcion,categoria,id_proyecto,id_mentor,participantes,fecha_creacion,estado,canal_chat_id,puntaje,historial"

    filas =
      equipos
      |> Enum.map(&serializar_equipo/1)
      |> Enum.join("\n")

    File.mkdir_p!("data")
    File.write!(@ruta_archivo, "#{encabezado}\n#{filas}")
  end

  @doc false
  defp parsear_linea_a_struct(linea) do
    [
      id,
      nombre,
      descripcion,
      categoria,
      id_proyecto,
      id_mentor,
      participantes,
      fecha_creacion,
      estado,
      canal_chat_id,
      puntaje,
      historial
    ] = String.split(linea, ",")

    %Team{
      id: id,
      nombre: nombre,
      descripcion: descripcion,
      categoria: categoria,
      id_proyecto: convertir_a_nil(id_proyecto),
      id_mentor: convertir_a_nil(id_mentor),
      participantes: decodificar_lista(participantes),
      fecha_creacion: parsear_fecha(fecha_creacion),
      estado: String.to_atom(estado),
      canal_chat_id: convertir_a_nil(canal_chat_id),
      puntaje: String.to_integer(puntaje),
      historial: decodificar_lista(historial)
    }
  end

  @doc false
  defp serializar_equipo(equipo) do
    [
      equipo.id,
      equipo.nombre,
      equipo.descripcion,
      equipo.categoria,
      equipo.id_proyecto || "",
      equipo.id_mentor || "",
      codificar_lista(equipo.participantes),
      DateTime.to_string(equipo.fecha_creacion),
      Atom.to_string(equipo.estado),
      equipo.canal_chat_id || "",
      equipo.puntaje,
      codificar_lista(equipo.historial)
    ]
    |> Enum.join(",")
  end

  @doc false
  defp convertir_a_nil(""), do: nil
  defp convertir_a_nil(valor), do: valor

  @doc false
  defp parsear_fecha(fecha_str) do
    case DateTime.from_iso8601(fecha_str) do
      {:ok, fecha, _offset} -> fecha
      _ -> DateTime.utc_now()
    end
  end

  @doc false
  defp codificar_lista(lista) when is_list(lista) do
    lista
    |> Enum.map(&inspect/1)
    |> Enum.join("|")
  end

  defp codificar_lista(_), do: ""

  @doc false
  defp decodificar_lista(cadena) do
    if cadena == "" do
      []
    else
      cadena
      |> String.split("|")
      |> Enum.map(&String.trim/1)
    end
  end
end
