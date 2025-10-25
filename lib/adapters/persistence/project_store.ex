defmodule ProyectoFinalPrg3.Adapters.Persistence.ProjectStore do
  @moduledoc """
  Implementa la capa de persistencia para los proyectos registrados en el sistema de hackathon.
  Gestiona las operaciones de lectura, escritura, actualización y eliminación de datos mediante
  archivos CSV almacenados en la carpeta `data/`.

  Autores: [Sharif Giraldo, Juan Sebastián Hernández y Santiago Ospina Sánchez]
  Fecha de creación: 2025-10-26
  Fecha de última modificación:
  Licencia: GNU GPLv3
  """

  alias ProyectoFinalPrg3.Domain.Project

  @ruta_archivo Path.join([File.cwd!(), "data", "proyectos.csv"])

  # ============================================================
  # FUNCIONES PRINCIPALES DE PERSISTENCIA
  # ============================================================

  @doc """
  Guarda un nuevo proyecto o actualiza uno existente en el archivo CSV.
  Si el proyecto ya existe (por nombre), se reemplaza su registro.
  Retorna `{:ok, proyecto}`.
  """
  def guardar_proyecto(proyecto = %Project{}) do
    proyectos = listar_proyectos()

    proyectos_actualizados =
      proyectos
      |> Enum.reject(&(&1.nombre == proyecto.nombre))
      |> Enum.concat([proyecto])

    persistir_en_csv(proyectos_actualizados)
    {:ok, proyecto}
  end

  @doc """
  Obtiene un proyecto por su nombre desde el archivo CSV.
  Retorna `{:ok, proyecto}` si se encuentra, o `nil` si no existe.
  """
  def obtener_proyecto(nombre) do
    proyectos = listar_proyectos()

    case Enum.find(proyectos, &(&1.nombre == nombre)) do
      nil -> nil
      proyecto -> {:ok, proyecto}
    end
  end

  @doc """
  Lista todos los proyectos registrados en el archivo CSV.
  Retorna una lista de estructuras `%Project{}`.
  """
  def listar_proyectos do
    case File.read(@ruta_archivo) do
      {:ok, contenido} ->
        contenido
        |> String.split("\n", trim: true)
        |> Enum.drop(1) # Omitir encabezado
        |> Enum.map(&parsear_linea_a_struct/1)

      {:error, :enoent} ->
        [] # Si el archivo no existe, retornar lista vacía
    end
  end

  @doc """
  Elimina un proyecto del archivo CSV usando su nombre como identificador.
  Retorna `:ok` si la operación se realiza correctamente.
  """
  def eliminar_proyecto(nombre) do
    proyectos =
      listar_proyectos()
      |> Enum.reject(&(&1.nombre == nombre))

    persistir_en_csv(proyectos)
    :ok
  end

  # ============================================================
  # FUNCIONES INTERNAS DE APOYO
  # ============================================================

  @doc false
  defp persistir_en_csv(proyectos) do
    encabezado =
      "id,nombre,descripcion,categoria,id_equipo,estado,avances,fecha_creacion,fecha_ultima_actualizacion,retroalimentaciones"

    filas =
      proyectos
      |> Enum.map(&serializar_proyecto/1)
      |> Enum.join("\n")

    File.mkdir_p!(Path.join(File.cwd!(), "data"))
    File.write!(@ruta_archivo, "#{encabezado}\n#{filas}")
  end

  @doc false
  defp parsear_linea_a_struct(linea) do
    [
      id,
      nombre,
      descripcion,
      categoria,
      id_equipo,
      estado,
      avances,
      fecha_creacion,
      fecha_ultima_actualizacion,
      retroalimentaciones
    ] = String.split(linea, ",")

    %Project{
      id: id,
      nombre: nombre,
      descripcion: descripcion,
      categoria: convertir_a_nil(categoria),
      id_equipo: convertir_a_nil(id_equipo),
      estado: String.to_atom(estado),
      avances: decodificar_lista(avances),
      fecha_creacion: parsear_fecha(fecha_creacion),
      fecha_ultima_actualizacion: parsear_fecha(fecha_ultima_actualizacion),
      retroalimentaciones: decodificar_lista(retroalimentaciones)
    }
  end

  @doc false
  defp serializar_proyecto(proyecto) do
    [
      proyecto.id,
      proyecto.nombre,
      proyecto.descripcion,
      proyecto.categoria || "",
      proyecto.id_equipo || "",
      Atom.to_string(proyecto.estado),
      codificar_lista(proyecto.avances),
      DateTime.to_string(proyecto.fecha_creacion),
      DateTime.to_string(proyecto.fecha_ultima_actualizacion),
      codificar_lista(proyecto.retroalimentaciones)
    ]
    |> Enum.join(",")
  end

  # ============================================================
  # FUNCIONES DE CONVERSIÓN Y FORMATEO
  # ============================================================

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
