defmodule ProyectoFinalPrg3.Adapters.Persistence.CategoryStore do
  @moduledoc """
  Persistencia de categorías en archivo CSV.
  Alineado al dominio Category (id, nombre, descripcion).
  """

  alias ProyectoFinalPrg3.Domain.Category

  @ruta Path.join([File.cwd!(), "data", "categorias.csv"])

  # ------------------------------------------------------------
  # GUARDAR / ACTUALIZAR
  # ------------------------------------------------------------

  @doc """
  Guarda o actualiza una categoría. Se identifica por `id`.
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
  Retorna {:ok, categoria} o nil si no existe.
  """
  def obtener_categoria(id) do
    case Enum.find(listar_categorias(), &(&1.id == id)) do
      nil -> nil
      categoria -> {:ok, categoria}
    end
  end

  @doc """
  Obtiene una categoría por su nombre (case-insensitive).
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
  """
  def listar_categorias do
    case File.read(@ruta) do
      {:ok, contenido} ->
        contenido
        |> String.split("\n", trim: true)
        |> Enum.drop(1)             # quitar encabezado
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

  defp persistir(categorias) do
    encabezado = "id,nombre,descripcion"

    filas =
      categorias
      |> Enum.map(&serializar/1)
      |> Enum.join("\n")

    File.mkdir_p!(Path.join(File.cwd!(), "data"))
    File.write!(@ruta, encabezado <> "\n" <> filas)
  end

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
  defp escapar(texto) when is_binary(texto) do
    if String.contains?(texto, ",") do
      "\"" <> texto <> "\""
    else
      texto
    end
  end

  # Permite parsear campos con comas dentro de comillas
  defp split_csv(linea) do
    Regex.scan(~r/"([^"]*)"|([^,]+)/, linea)
    |> Enum.map(fn
      [_, quoted, _] -> quoted
      [_, _, normal] -> normal
    end)
  end
end
