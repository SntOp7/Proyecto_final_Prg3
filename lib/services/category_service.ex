defmodule ProyectoFinalPrg3.Services.CategoryService do
  @moduledoc """
  Servicio responsable de la **gestión de categorías** dentro del sistema Hackathon.

  Permite crear, listar, actualizar, eliminar y filtrar categorías que agrupan
  proyectos según su temática (por ejemplo, *Educación*, *Salud*, *Innovación Social*, etc.).

  Este módulo pertenece a la capa de **servicios** dentro de la arquitectura hexagonal
  y coordina la comunicación entre el dominio (`Category`) y los adaptadores de persistencia
  (`CategoryStore`) y de eventos (`BroadcastService`).

  ---
  **Autores:** Sharif Giraldo, Juan Sebastián Hernández y Santiago Ospina Sánchez
  **Fecha de creación:** 2025-10-27
  **Licencia:** GNU GPLv3
  """

  alias ProyectoFinalPrg3.Domain.Category
  alias ProyectoFinalPrg3.Adapters.Persistence.CategoryStore
  alias ProyectoFinalPrg3.Services.BroadcastService

  # ============================================================
  # FUNCIONES PRINCIPALES DE GESTIÓN DE CATEGORÍAS
  # ============================================================

  @doc """
  Crea una nueva categoría dentro del sistema Hackathon.

  Verifica que no exista previamente una categoría con el mismo nombre y
  la registra con estado activo.

  ## Parámetros:
    - `nombre`: Nombre descriptivo de la categoría.
    - `descripcion`: Breve texto explicativo de su propósito.
    - `creador_id`: ID del usuario o administrador que la define (opcional).

  ## Retorna:
    - `{:ok, categoria}` si se crea exitosamente.
    - `{:error, :categoria_existente}` si ya hay una categoría con ese nombre.
  """
  def crear_categoria(nombre, descripcion \\ "", creador_id \\ nil) do
    case CategoryStore.buscar_por_nombre(nombre) do
      nil ->
        categoria = %Category{
          id: UUID.uuid4(),
          nombre: nombre,
          descripcion: descripcion,
          proyectos: [],
          fecha_creacion: DateTime.utc_now(),
          creador_id: creador_id,
          activo: true
        }

        CategoryStore.guardar_categoria(categoria)
        BroadcastService.notificar(:categoria_creada, categoria)
        {:ok, categoria}

      _existente ->
        {:error, :categoria_existente}
    end
  end

  @doc """
  Actualiza los datos de una categoría existente.

  Permite modificar la descripción, el estado o la lista de proyectos asociados.
  """
  def actualizar_categoria(id_categoria, nuevos_datos) when is_map(nuevos_datos) do
    with {:ok, categoria} <- obtener_categoria(id_categoria) do
      actualizada =
        categoria
        |> Map.merge(nuevos_datos)
        |> Map.put(:fecha_modificacion, DateTime.utc_now())

      CategoryStore.guardar_categoria(actualizada)
      BroadcastService.notificar(:categoria_actualizada, actualizada)
      {:ok, actualizada}
    else
      {:error, razon} -> {:error, razon}
    end
  end

  @doc """
  Elimina una categoría del sistema según su identificador.
  """
  def eliminar_categoria(id_categoria) do
    with {:ok, categoria} <- obtener_categoria(id_categoria) do
      CategoryStore.eliminar_categoria(id_categoria)
      BroadcastService.notificar(:categoria_eliminada, categoria)
      {:ok, :eliminada}
    else
      {:error, razon} -> {:error, razon}
    end
  end

  # ============================================================
  # FUNCIONES DE CONSULTA Y VALIDACIÓN
  # ============================================================

  @doc """
  Lista todas las categorías registradas.
  """
  def listar_categorias do
    CategoryStore.listar_categorias()
  end

  @doc """
  Obtiene una categoría por su identificador único.

  Retorna:
    - `{:ok, categoria}` si existe.
    - `{:error, :no_encontrada}` en caso contrario.
  """
  def obtener_categoria(id_categoria) do
    case CategoryStore.obtener_categoria(id_categoria) do
      nil -> {:error, :no_encontrada}
      categoria -> {:ok, categoria}
    end
  end

  @doc """
  Busca una categoría por su nombre (insensible a mayúsculas).
  """
  def buscar_por_nombre(nombre) do
    case CategoryStore.buscar_por_nombre(nombre) do
      nil -> {:error, :no_encontrada}
      categoria -> {:ok, categoria}
    end
  end

  @doc """
  Verifica si una categoría ya existe en el sistema.
  """
  def categoria_existe?(nombre) do
    case CategoryStore.buscar_por_nombre(nombre) do
      nil -> false
      _ -> true
    end
  end

  # ============================================================
  # FUNCIONES DE ESTADO Y FILTRADO
  # ============================================================

  @doc """
  Cambia el estado de una categoría (`true` para activa, `false` para inactiva).
  """
  def cambiar_estado(id_categoria, activo) when is_boolean(activo) do
    with {:ok, categoria} <- obtener_categoria(id_categoria) do
      actualizada = %{categoria | activo: activo}
      CategoryStore.guardar_categoria(actualizada)
      BroadcastService.notificar(:categoria_estado_cambiado, actualizada)
      {:ok, actualizada}
    else
      {:error, razon} -> {:error, razon}
    end
  end

  @doc """
  Filtra las categorías según su estado (`true` = activas, `false` = inactivas).
  """
  def filtrar_por_estado(activo) when is_boolean(activo) do
    listar_categorias()
    |> Enum.filter(&(&1.activo == activo))
  end

  # ============================================================
  # FUNCIONES DE RELACIÓN CON PROYECTOS
  # ============================================================

  @doc """
  Agrega un proyecto a la lista de proyectos asociados a una categoría.
  """
  def agregar_proyecto(id_categoria, id_proyecto) do
    with {:ok, categoria} <- obtener_categoria(id_categoria) do
      actualizada = %{categoria | proyectos: Enum.uniq([id_proyecto | categoria.proyectos])}
      CategoryStore.guardar_categoria(actualizada)
      BroadcastService.notificar(:proyecto_agregado_categoria, actualizada)
      {:ok, actualizada}
    else
      {:error, razon} -> {:error, razon}
    end
  end

  @doc """
  Elimina un proyecto asociado de una categoría.
  """
  def remover_proyecto(id_categoria, id_proyecto) do
    with {:ok, categoria} <- obtener_categoria(id_categoria) do
      actualizada = %{categoria | proyectos: Enum.reject(categoria.proyectos, &(&1 == id_proyecto))}
      CategoryStore.guardar_categoria(actualizada)
      BroadcastService.notificar(:proyecto_removido_categoria, actualizada)
      {:ok, actualizada}
    else
      {:error, razon} -> {:error, razon}
    end
  end
end
