defmodule ProyectoFinalPrg3.Services.CategoryService do
  @moduledoc """
  Servicio responsable de la gestión de categorías del hackathon.
  """

  alias ProyectoFinalPrg3.Domain.Category
  alias ProyectoFinalPrg3.Adapters.Persistence.CategoryStore
  alias ProyectoFinalPrg3.Services.BroadcastService

  # ============================================================
  # CREACIÓN
  # ============================================================

  @doc """
  Crea una nueva categoría.

  - Valida que no exista otra con el mismo nombre.
  - Genera un `id` automáticamente.

  Retorna:
    - {:ok, categoria}
    - {:error, :categoria_existente}
  """
  def crear_categoria(nombre, descripcion \\ "") do
    if categoria_existe?(nombre) do
      {:error, :categoria_existente}
    else
      categoria =
        Category.nuevo(
          UUID.uuid4(),
          nombre,
          descripcion
        )

      CategoryStore.guardar_categoria(categoria)
      BroadcastService.notificar(:categoria_creada, categoria)

      {:ok, categoria}
    end
  end

  # ============================================================
  # ACTUALIZACIÓN
  # ============================================================

  @doc """
  Actualiza una categoría existente.

  Solo permite actualizar:
  - nombre
  - descripcion
  """
  def actualizar_categoria(id, %{nombre: nombre, descripcion: descripcion}) do
    with {:ok, categoria} <- obtener_categoria(id) do
      actualizada = Map.merge(categoria, %{nombre: nombre, descripcion: descripcion})
      CategoryStore.guardar_categoria(actualizada)

      BroadcastService.notificar(:categoria_actualizada, actualizada)
      {:ok, actualizada}
    else
      {:error, razon} -> {:error, razon}
    end
  end

  def actualizar_categoria(_id, _datos_invalidos) do
    {:error, :datos_invalidos}
  end

  # ============================================================
  # ELIMINAR
  # ============================================================

  @doc """
  Elimina una categoría por id.
  """
  def eliminar_categoria(id) do
    with {:ok, categoria} <- obtener_categoria(id) do
      CategoryStore.eliminar_categoria(id)
      BroadcastService.notificar(:categoria_eliminada, categoria)
      {:ok, :eliminada}
    else
      {:error, razon} -> {:error, razon}
    end
  end

  # ============================================================
  # CONSULTAS
  # ============================================================

  def listar_categorias do
    CategoryStore.listar_categorias()
  end

  def obtener_categoria(id) do
    case CategoryStore.obtener_categoria(id) do
      nil -> {:error, :no_encontrada}
      categoria -> {:ok, categoria}
    end
  end

  def buscar_por_nombre(nombre) do
    lista = listar_categorias()

    case Enum.find(lista, fn c ->
           String.downcase(c.nombre) == String.downcase(nombre)
         end) do
      nil -> {:error, :no_encontrada}
      categoria -> {:ok, categoria}
    end
  end

  def categoria_existe?(nombre) do
    case buscar_por_nombre(nombre) do
      {:ok, _} -> true
      _ -> false
    end
  end
end
