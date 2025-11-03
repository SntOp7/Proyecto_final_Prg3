defmodule ProyectoFinalPrg3.Adapters.Persistence.CategoryStore do
  @moduledoc """
  Define el repositorio general de persistencia del sistema.
  Este módulo actúa como punto de acceso unificado para los distintos mecanismos de
  almacenamiento de datos (equipos, proyectos, categorías, etc.) a través de submódulos
  especializados que gestionan cada tipo de entidad.

  Autores: [Sharif Giraldo, Juan Sebastián Hernández y Santiago Ospina Sánchez]
  Fecha de creación: 2025-10-26
  Fecha de última modificación:
  Licencia: GNU GPLv3
  """

  alias ProyectoFinalPrg3.Domain.Category

  @ruta_archivo Path.join([File.cwd!(), "data", "categorias.csv"])

  # ------------------------------------------------------------
  # FUNCIONES PRINCIPALES DE PERSISTENCIA
  # ------------------------------------------------------------

  @doc """
  Guarda una nueva categoría o actualiza una existente en el archivo CSV.
  Retorna `{:ok, categoria}`.
  """
  def guardar_categoria(categoria = %Category{}) do
    categorias = listar_categorias()

    categorias_actualizadas =
      categorias
      |> Enum.reject(&(&1.nombre == categoria.nombre))
      |> Enum.concat([categoria])

    persistir_en_csv(categorias_actualizadas)
    {:ok, categoria}
  end

  @doc """
  Obtiene una categoría por su nombre desde el archivo CSV.
  Retorna `{:ok, categoria}` si se encuentra, o `nil` si no existe.
  """
  def obtener_categoria(nombre) do
    categorias = listar_categorias()

    case Enum.find(categorias, &(&1.nombre == nombre)) do
      nil -> nil
      categoria -> {:ok, categoria}
    end
  end

  @doc """
  Lista todas las categorías registradas en el sistema.
  Retorna una lista de estructuras `%Category{}`.
  """
  def listar_categorias do
    case File.read(@ruta_archivo) do
      {:ok, contenido} ->
        contenido
        |> String.split("\n", trim: true)
        |> Enum.drop(1)
        |> Enum.map(&parsear_linea_a_struct/1)

      {:error, :enoent} ->
        # Si no existe el archivo, retornar lista vacía
        []
    end
  end

  @doc """
  Elimina una categoría del archivo CSV según su nombre.
  Retorna `:ok` si la operación fue exitosa.
  """
  def eliminar_categoria(nombre) do
    categorias =
      listar_categorias()
      |> Enum.reject(&(&1.nombre == nombre))

    persistir_en_csv(categorias)
    :ok
  end

  # ------------------------------------------------------------
  # FUNCIONES INTERNAS DE APOYO
  # ------------------------------------------------------------

  @doc false
  defp persistir_en_csv(categorias) do
    encabezado = "id,nombre,descripcion,proyectos,fecha_creacion,creador_id,activo"

    filas =
      categorias
      |> Enum.map(&serializar_categoria/1)
      |> Enum.join("\n")

    File.mkdir_p!(Path.join(File.cwd!(), "data"))
    File.write!(@ruta_archivo, "#{encabezado}\n#{filas}")
  end

  @doc false
  defp parsear_linea_a_struct(linea) do
    [id, nombre, descripcion, proyectos_str, fecha_creacion, creador_id, activo_str] =
      String.split(linea, ",")

    %Category{
      id: id,
      nombre: nombre,
      descripcion: descripcion,
      proyectos: parsear_proyectos(proyectos_str),
      fecha_creacion: parsear_fecha(fecha_creacion),
      creador_id: creador_id,
      activo: String.downcase(activo_str) in ["true", "1", "yes", "activo"]
    }
  end

  @doc false
  defp serializar_categoria(categoria) do
    proyectos_str = serializar_proyectos(categoria.proyectos)

    [
      categoria.id,
      categoria.nombre,
      categoria.descripcion,
      proyectos_str,
      DateTime.to_string(categoria.fecha_creacion),
      categoria.creador_id,
      to_string(categoria.activo)
    ]
    |> Enum.join(",")
  end

  @doc false
  defp parsear_proyectos(""), do: []
  defp parsear_proyectos(str), do: String.split(str, ";", trim: true)

  @doc false
  defp serializar_proyectos(nil), do: ""
  defp serializar_proyectos([]), do: ""
  defp serializar_proyectos(lista) when is_list(lista), do: Enum.join(lista, ";")

  @doc false
  defp parsear_fecha(fecha_str) do
    case DateTime.from_iso8601(fecha_str) do
      {:ok, fecha, _offset} -> fecha
      _ -> DateTime.utc_now()
    end
  end
end
