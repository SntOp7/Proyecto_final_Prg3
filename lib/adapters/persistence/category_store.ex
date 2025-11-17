defmodule ProyectoFinalPrg3.Adapters.Persistence.CategoryStore do
  @moduledoc """
  Persistencia de categorías en archivo CSV.
  Alineado al dominio Category (id, nombre, descripcion).
  Proporciona funciones para guardar, obtener, listar y eliminar categorías.
  Autores: [Sharif Giraldo Obando, Juan Sebastián Hernández y Santiago Ospina Sánchez]
  Fecha de creación: 2025-11-16
  Fecha de última modificación: 2025-11-16
  Licencia: GNU GPL v3
  """

  alias ProyectoFinalPrg3.Domain.Category

  @ruta Path.join([File.cwd!(), "data", "categorias.csv"])

  # ------------------------------------------------------------
  # GUARDAR / ACTUALIZAR
  # ------------------------------------------------------------

  @doc """
  Guarda o actualiza una categoría. Se identifica por `id`.
  Parametros:
    - `categoria`: Struct %Category{} a guardar o actualizar.
  Retorna:
    - `{:ok, categoria}` confirmando la operación.
  """
  def guardar_categoria(%Category{} = categoria) do
    categorias =
      listar_categorias()
      |> Enum.reject(&(&1.id == categoria.id))

    persistir([categoria | categorias])
    {:ok, categoria}
  end

  # ------------------------------------------------------------
  # OBTENER
  # ------------------------------------------------------------

  @doc """
  Obtiene una categoría por su id.

  Parámetros:
    - `id`: Identificador único de la categoría.

  Retorna:
    - `{:ok, categoria}` si se encuentra la categoría.
    - `nil` si no existe.
  """
  def obtener_categoria(id) do
    case Enum.find(listar_categorias(), &(&1.id == id)) do
      nil -> nil
      categoria -> {:ok, categoria}
    end
  end

  @doc """
  Obtiene una categoría por su nombre (case-insensitive).
  Parámetros:
    - `nombre`: Nombre de la categoría.
  Retorna:
    - `categoria` si se encuentra.
    - `nil` si no existe.
  """
  def obtener_categoria_por_nombre(nombre) do
    nombre = String.downcase(nombre)

    Enum.find(listar_categorias(), fn c ->
      String.downcase(c.nombre) == nombre
    end)
  end

  # ------------------------------------------------------------
  # LISTAR
  # ------------------------------------------------------------

  @doc """
  Devuelve todas las categorías como structs %Category{}
  Parámetros: Ninguno.
  Retorna:
    - Lista de categorías.
  """
  def listar_categorias do
    case File.read(@ruta) do
      {:ok, contenido} ->
        contenido
        |> String.split("\n", trim: true)
        # quitar encabezado
        |> Enum.drop(1)
        |> Enum.map(&parsear_linea/1)

      {:error, :enoent} ->
        []
    end
  end

  # ------------------------------------------------------------
  # ELIMINAR
  # ------------------------------------------------------------

  @doc """
  Elimina una categoría por su id.
  Parámetros:
    - `id`: Identificador único de la categoría a eliminar.
  Retorna:
    - `:ok` al completar la operación.
  """
  def eliminar_categoria(id) do
    categorias =
      listar_categorias()
      |> Enum.reject(&(&1.id == id))

    persistir(categorias)
    :ok
  end

  # ------------------------------------------------------------
  # CSV (INTERNO)
  # ------------------------------------------------------------

  @doc false
  defp persistir(categorias) do
    encabezado = "id,nombre,descripcion"

    filas =
      categorias
      |> Enum.map(&serializar/1)
      |> Enum.join("\n")

    File.mkdir_p!(Path.join(File.cwd!(), "data"))
    File.write!(@ruta, encabezado <> "\n" <> filas)
  end


  @doc false
  defp serializar(%Category{id: id, nombre: nombre, descripcion: descripcion}) do
    [
      id,
      escapar(nombre),
      escapar(descripcion)
    ]
    |> Enum.join(",")
  end

  # ------------------------------------------------------------
  # PARSING
  # ------------------------------------------------------------

  @doc false
  defp parsear_linea(linea) do
    [id, nombre, descripcion] =
      linea
      |> split_csv()

    %Category{
      id: id,
      nombre: nombre,
      descripcion: descripcion
    }
  end

  # ------------------------------------------------------------
  # UTILIDADES CSV SEGUROS
  # ------------------------------------------------------------

  # Manejo seguro de comas en descripción y nombre
  @doc false
  defp escapar(texto) when is_binary(texto) do
    if String.contains?(texto, ",") do
      "\"" <> texto <> "\""
    else
      texto
    end
  end

  # Permite parsear campos con comas dentro de comillas
  @doc false
  defp split_csv(linea) do
    Regex.scan(~r/"([^"]*)"|([^,]+)/, linea)
    |> Enum.map(fn
      [_, quoted, nil] -> quoted
      [_, nil, normal] -> normal
      _ -> ""
    end)
  end
end
