defmodule ProyectoFinalPrg3.Services.CategoryService do
  @moduledoc """
  Define la lógica de negocio para la gestión de categorías dentro del sistema de hackathon.
  Este módulo permite crear, listar, actualizar y eliminar categorías, así como validar su existencia
  para garantizar la correcta clasificación de proyectos y equipos.

  Autores: [Sharif Giraldo, Juan Sebastián Hernández y Santiago Ospina Sánchez]
  Fecha de creación: 2025-10-26
  Fecha de última modificación:
  Licencia: GNU GPLv3
  """

  alias ProyectoFinalPrg3.Domain.Category
  alias ProyectoFinalPrg3.Adapters.Persistence.Repository.CategoryStore
  alias ProyectoFinalPrg3.Services.BroadcastService

  # ============================================================
  # FUNCIONES PRINCIPALES DE GESTIÓN DE CATEGORÍAS
  # ============================================================

  @doc """
  Crea una nueva categoría dentro del sistema.
  Verifica que no exista previamente una categoría con el mismo nombre.
  """
  def crear_categoria(nombre, descripcion \\ "") do
    case CategoryStore.obtener_categoria(nombre) do
      nil ->
        categoria = %Category{
          id: UUID.uuid4(),
          nombre: nombre,
          descripcion: descripcion,
          fecha_creacion: DateTime.utc_now(),
          estado: :activa
        }

        CategoryStore.guardar_categoria(categoria)
        BroadcastService.notificar(:categoria_creada, categoria)
        {:ok, categoria}

      _existente ->
        {:error, :categoria_ya_existente}
    end
  end

  @doc """
  Actualiza los datos de una categoría existente.
  Permite modificar su descripción o estado.
  """
  def actualizar_categoria(nombre, nuevos_datos) do
    with {:ok, categoria} <- obtener_categoria(nombre) do
      categoria_actualizada =
        categoria
        |> Map.merge(nuevos_datos)
        |> Map.put(:fecha_modificacion, DateTime.utc_now())

      CategoryStore.guardar_categoria(categoria_actualizada)
      BroadcastService.notificar(:categoria_actualizada, categoria_actualizada)
      {:ok, categoria_actualizada}
    else
      {:error, razon} -> {:error, razon}
    end
  end

  @doc """
  Elimina una categoría existente del sistema.
  """
  def eliminar_categoria(nombre) do
    with {:ok, categoria} <- obtener_categoria(nombre) do
      CategoryStore.eliminar_categoria(nombre)
      BroadcastService.notificar(:categoria_eliminada, categoria)
      :ok
    else
      {:error, razon} -> {:error, razon}
    end
  end

  # ============================================================
  # FUNCIONES DE CONSULTA Y VALIDACIÓN
  # ============================================================

  @doc """
  Lista todas las categorías registradas en el sistema.
  """
  def listar_categorias do
    CategoryStore.listar_categorias()
  end

  @doc """
  Obtiene la información completa de una categoría a partir de su nombre.
  Retorna `{:ok, categoria}` si existe, o `{:error, :no_encontrada}` en caso contrario.
  """
  def obtener_categoria(nombre) do
    case CategoryStore.obtener_categoria(nombre) do
      nil -> {:error, :no_encontrada}
      categoria -> {:ok, categoria}
    end
  end

  @doc """
  Verifica si una categoría existe en el sistema.
  Retorna `true` si se encuentra registrada, o `false` en caso contrario.
  """
  def categoria_existe?(nombre) do
    case CategoryStore.obtener_categoria(nombre) do
      nil -> false
      _ -> true
    end
  end

  # ============================================================
  # FUNCIONES DE ESTADO Y FILTRADO
  # ============================================================

  @doc """
  Cambia el estado de una categoría (por ejemplo: `:activa` o `:inactiva`).
  """
  def actualizar_estado(nombre, nuevo_estado) do
    with {:ok, categoria} <- obtener_categoria(nombre) do
      categoria_actualizada = %{categoria | estado: nuevo_estado, fecha_modificacion: DateTime.utc_now()}
      CategoryStore.guardar_categoria(categoria_actualizada)
      BroadcastService.notificar(:estado_categoria_actualizado, categoria_actualizada)
      {:ok, categoria_actualizada}
    else
      {:error, razon} -> {:error, razon}
    end
  end

  @doc """
  Filtra las categorías registradas según su estado actual.
  """
  def filtrar_categorias(estado) do
    listar_categorias()
    |> Enum.filter(&(&1.estado == estado))
  end
end
