defmodule ProyectoFinalPrg3.Adapters.Persistence.ProjectStore do
  @moduledoc """
  Módulo encargado de la persistencia de proyectos en el sistema.
  Gestiona el almacenamiento, lectura, actualización y eliminación de proyectos,
  utilizando un formato CSV para mantener una estructura ligera y portable.

  Este módulo actúa como el adaptador de persistencia dentro de la arquitectura hexagonal,
  proporcionando una interfaz de bajo nivel utilizada por `ProjectManager`.

  Autores: [Sharif Giraldo, Juan Sebastián Hernández y Santiago Ospina Sánchez]
  Fecha de creación: 2025-10-26
  Licencia: GNU GPLv3
  """

  alias ProyectoFinalPrg3.Domain.Project
  @ruta_archivo Path.join([File.cwd!(), "data", "proyectos.csv"])

  # ============================================================
  # FUNCIONES PÚBLICAS PRINCIPALES (INTERFAZ)
  # ============================================================

  @doc """
  Guarda o actualiza un proyecto en el archivo CSV.
  Si ya existe un proyecto con el mismo nombre, se reemplaza.
  """
  def guardar_proyecto(%Project{} = proyecto) do
    proyectos = listar_proyectos()
    proyectos_actualizados =
      proyectos
      |> Enum.reject(&(&1.nombre == proyecto.nombre))
      |> Kernel.++([proyecto])

    persistir_lista(proyectos_actualizados)
  end

  @doc """
  Devuelve una lista de todos los proyectos almacenados.
  """
  def listar_proyectos do
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
  Elimina un proyecto a partir de su nombre.
  """
  def eliminar_proyecto(nombre) do
    proyectos =
      listar_proyectos()
      |> Enum.reject(&(&1.nombre == nombre))

    persistir_lista(proyectos)
  end

  # ============================================================
  # FUNCIONES INTERNAS DE PERSISTENCIA
  # ============================================================

  @doc false
  defp persistir_lista(lista_proyectos) do
    File.mkdir_p!("data")

    contenido =
      lista_proyectos
      |> Enum.map(&serializar_proyecto/1)
      |> Enum.join("\n")

    File.write!(@data_file, contenido)
  end

  @doc false
  defp serializar_proyecto(%Project{} = proyecto) do
    [
      proyecto.id,
      proyecto.nombre,
      proyecto.descripcion,
      proyecto.categoria,
      Atom.to_string(proyecto.estado),
      proyecto.equipo_id || "",
      proyecto.mentor_id || "",
      proyecto.repositorio_url || "",
      proyecto.puntaje,
      Atom.to_string(proyecto.visibilidad),
      Enum.join(proyecto.tags, ";"),
      serialize_timestamp(proyecto.fecha_creacion),
      serialize_timestamp(proyecto.fecha_actualizacion),
      serializar_lista(proyecto.avances),
      serializar_lista(proyecto.retroalimentaciones)
    ]
    |> Enum.join(",")
  end

  @doc false
  defp parsear_linea(linea) do
    [
      id,
      nombre,
      descripcion,
      categoria,
      estado,
      equipo_id,
      mentor_id,
      repositorio_url,
      puntaje,
      visibilidad,
      tags,
      fecha_creacion,
      fecha_actualizacion,
      avances_serializados,
      feedbacks_serializados
    ] =
      String.split(linea, ",", parts: 15)

    %Project{
      id: id,
      nombre: nombre,
      descripcion: descripcion,
      categoria: categoria,
      estado: String.to_atom(estado),
      equipo_id: parse_blank(equipo_id),
      mentor_id: parse_blank(mentor_id),
      repositorio_url: parse_blank(repositorio_url),
      puntaje: String.to_integer(puntaje),
      visibilidad: String.to_atom(visibilidad),
      tags: if(tags == "", do: [], else: String.split(tags, ";")),
      fecha_creacion: parse_timestamp(fecha_creacion),
      fecha_actualizacion: parse_timestamp(fecha_actualizacion),
      avances: deserializar_lista(avances_serializados),
      retroalimentaciones: deserializar_lista(feedbacks_serializados)
    }
  end

  # ============================================================
  # FUNCIONES AUXILIARES DE SERIALIZACIÓN
  # ============================================================

  @doc false
  defp parse_blank(""), do: nil
  defp parse_blank(valor), do: valor

  @doc false
  defp serialize_timestamp(nil), do: ""
  defp serialize_timestamp(%DateTime{} = dt), do: DateTime.to_iso8601(dt)

  @doc false
  defp parse_timestamp(""), do: nil
  defp parse_timestamp(valor) do
    case DateTime.from_iso8601(valor) do
      {:ok, dt, _offset} -> dt
      _ -> nil
    end
  end

  @doc false
  defp serializar_lista(lista) when is_list(lista) do
    lista
    |> Enum.map(&Jason.encode!/1)
    |> Enum.join("|")
  end

  @doc false
  defp deserializar_lista(""), do: []
  defp deserializar_lista(serializado) do
    serializado
    |> String.split("|")
    |> Enum.map(fn e ->
      case Jason.decode(e) do
        {:ok, val} -> val
        _ -> nil
      end
    end)
    |> Enum.reject(&is_nil/1)
  end
end
