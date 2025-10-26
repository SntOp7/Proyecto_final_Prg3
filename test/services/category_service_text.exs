defmodule ProyectoFinalPrg3.Test.Services.CategoryServiceTest do
  use ExUnit.Case, async: true
  import Mox

  alias ProyectoFinalPrg3.Services.CategoryService
  alias ProyectoFinalPrg3.Domain.Category

  @moduledoc """
  Pruebas unitarias para `CategoryService`.

  Se validan las principales operaciones de gestión de categorías:
  - Creación, actualización y eliminación.
  - Listado, consulta y filtrado.
  - Cambios de estado (activo/inactivo) y validación de existencia.
  - Difusión de eventos mediante `BroadcastService`.

  Los módulos `CategoryStore` y `BroadcastService` se simulan con `Mox`
  para garantizar aislamiento y control de las dependencias.
  """

  setup :verify_on_exit!

  # ============================================================
  # CREAR CATEGORÍA
  # ============================================================

  describe "crear_categoria/2" do
    test "crea una categoría nueva si no existe previamente" do
      expect(CategoryStoreMock, :obtener_categoria, fn "IA" -> nil end)
      expect(CategoryStoreMock, :guardar_categoria, fn cat -> cat end)
      expect(BroadcastServiceMock, :notificar, fn :categoria_creada, %Category{} -> :ok end)

      {:ok, categoria} = CategoryService.crear_categoria("IA", "Inteligencia Artificial")

      assert categoria.nombre == "IA"
      assert categoria.descripcion == "Inteligencia Artificial"
      assert categoria.activo == true
      assert match?(%DateTime{}, categoria.fecha_creacion)
    end

    test "retorna error si la categoría ya existe" do
      expect(CategoryStoreMock, :obtener_categoria, fn "Salud" -> %Category{nombre: "Salud"} end)

      assert {:error, :categoria_ya_existente} =
               CategoryService.crear_categoria("Salud", "Sector salud")
    end
  end

  # ============================================================
  # ACTUALIZAR CATEGORÍA
  # ============================================================

  describe "actualizar_categoria/2" do
    setup do
      categoria = %Category{nombre: "Educación", descripcion: "Original", activo: true}
      {:ok, categoria: categoria}
    end

    test "actualiza correctamente una categoría existente", %{categoria: categoria} do
      expect(CategoryStoreMock, :obtener_categoria, fn "Educación" -> categoria end)
      expect(CategoryStoreMock, :guardar_categoria, fn c -> c end)
      expect(BroadcastServiceMock, :notificar, fn :categoria_actualizada, _ -> :ok end)

      {:ok, actualizada} =
        CategoryService.actualizar_categoria("Educación", %{descripcion: "Actualizada"})

      assert actualizada.descripcion == "Actualizada"
      assert match?(%DateTime{}, actualizada.fecha_modificacion)
    end

    test "retorna error si la categoría no existe" do
      expect(CategoryStoreMock, :obtener_categoria, fn "Desconocida" -> nil end)
      assert {:error, :no_encontrada} =
               CategoryService.actualizar_categoria("Desconocida", %{descripcion: "Nada"})
    end
  end

  # ============================================================
  # ELIMINAR CATEGORÍA
  # ============================================================

  describe "eliminar_categoria/1" do
    setup do
      categoria = %Category{nombre: "Social", activo: true}
      {:ok, categoria: categoria}
    end

    test "elimina una categoría existente", %{categoria: categoria} do
      expect(CategoryStoreMock, :obtener_categoria, fn "Social" -> categoria end)
      expect(CategoryStoreMock, :eliminar_categoria, fn "Social" -> :ok end)
      expect(BroadcastServiceMock, :notificar, fn :categoria_eliminada, _ -> :ok end)

      assert :ok = CategoryService.eliminar_categoria("Social")
    end

    test "retorna error si la categoría no existe" do
      expect(CategoryStoreMock, :obtener_categoria, fn _ -> nil end)
      assert {:error, :no_encontrada} = CategoryService.eliminar_categoria("Inexistente")
    end
  end

  # ============================================================
  # CONSULTAS Y VALIDACIONES
  # ============================================================

  describe "obtener_categoria/1 y categoria_existe?/1" do
    test "devuelve {:ok, categoria} si existe" do
      expect(CategoryStoreMock, :obtener_categoria, fn "IA" -> %Category{nombre: "IA"} end)
      assert {:ok, %Category{nombre: "IA"}} = CategoryService.obtener_categoria("IA")
      assert CategoryService.categoria_existe?("IA")
    end

    test "devuelve {:error, :no_encontrada} si no existe" do
      expect(CategoryStoreMock, :obtener_categoria, fn _ -> nil end)
      assert {:error, :no_encontrada} = CategoryService.obtener_categoria("Nada")
      refute CategoryService.categoria_existe?("Nada")
    end
  end

  describe "listar_categorias/0" do
    test "devuelve lista de categorías" do
      categorias = [
        %Category{nombre: "IA", activo: true},
        %Category{nombre: "Salud", activo: false}
      ]

      expect(CategoryStoreMock, :listar_categorias, fn -> categorias end)

      assert length(CategoryService.listar_categorias()) == 2
    end
  end

  # ============================================================
  # ESTADOS Y FILTRADO (activo/inactivo)
  # ============================================================

  describe "actualizar_estado/2" do
    test "cambia el estado (activo/inactivo) de una categoría" do
      categoria = %Category{nombre: "IA", activo: true}

      expect(CategoryStoreMock, :obtener_categoria, fn "IA" -> categoria end)
      expect(CategoryStoreMock, :guardar_categoria, fn c -> c end)
      expect(BroadcastServiceMock, :notificar, fn :estado_categoria_actualizado, _ -> :ok end)

      {:ok, actualizada} = CategoryService.actualizar_estado("IA", false)
      assert actualizada.activo == false
      assert match?(%DateTime{}, actualizada.fecha_modificacion)
    end

    test "retorna error si la categoría no existe" do
      expect(CategoryStoreMock, :obtener_categoria, fn _ -> nil end)
      assert {:error, :no_encontrada} = CategoryService.actualizar_estado("Fake", true)
    end
  end

  describe "filtrar_categorias/1" do
    test "filtra categorías activas o inactivas correctamente" do
      categorias = [
        %Category{nombre: "IA", activo: true},
        %Category{nombre: "Salud", activo: false},
        %Category{nombre: "Educación", activo: true}
      ]

      expect(CategoryStoreMock, :listar_categorias, fn -> categorias end)

      activas = CategoryService.filtrar_categorias(true)
      inactivas = CategoryService.filtrar_categorias(false)

      assert length(activas) == 2
      assert Enum.all?(activas, &(&1.activo == true))
      assert Enum.all?(inactivas, &(&1.activo == false))
    end
  end
end
