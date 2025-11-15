defmodule ProyectoFinalPrg3.Adapters.Persistence.CategoryStoreTest do
  use ExUnit.Case, async: false

  alias ProyectoFinalPrg3.Adapters.Persistence.CategoryStore
  alias ProyectoFinalPrg3.Domain.Category

  @encabezado "id,nombre,descripcion,proyectos,fecha_creacion,creador_id,activo\n"

  # ------------------------------------------------------------
  # CONFIGURACIÓN DEL ENTORNO DE PRUEBAS
  # ------------------------------------------------------------

  setup do
    data_path = Path.join(File.cwd!(), "data")
    file = Path.join(data_path, "categorias.csv")

    File.rm_rf!(data_path)
    File.mkdir_p!(data_path)

    File.write!(file, @encabezado)

    {:ok, file: file}
  end

  # ------------------------------------------------------------
  # UTILIDADES
  # ------------------------------------------------------------

  defp categoria_base(attrs \\ %{}) do
    %Category{
      id: Map.get(attrs, :id, "cat001"),
      nombre: Map.get(attrs, :nombre, "IA"),
      descripcion: Map.get(attrs, :descripcion, "Categoría de inteligencia artificial"),
      proyectos: Map.get(attrs, :proyectos, ["proj1", "proj2"]),
      fecha_creacion: Map.get(attrs, :fecha_creacion, DateTime.utc_now()),
      creador_id: Map.get(attrs, :creador_id, "user123"),
      activo: Map.get(attrs, :activo, true)
    }
  end

  # ------------------------------------------------------------
  # guardar_categoria/1
  # ------------------------------------------------------------

  describe "guardar_categoria/1" do
    test "guarda una categoría nueva en el CSV", %{file: file} do
      categoria = categoria_base()

      assert {:ok, ^categoria} = CategoryStore.guardar_categoria(categoria)

      contenido = File.read!(file)
      assert contenido =~ categoria.nombre
      assert contenido =~ categoria.descripcion
    end

    test "si la categoría ya existe, la reemplaza", %{file: _file} do
      c1 = categoria_base(descripcion: "Original")
      c2 = categoria_base(descripcion: "Actualizada")

      CategoryStore.guardar_categoria(c1)
      CategoryStore.guardar_categoria(c2)

      categorias = CategoryStore.listar_categorias()
      assert length(categorias) == 1
      assert hd(categorias).descripcion == "Actualizada"
    end
  end

  # ------------------------------------------------------------
  # obtener_categoria/1
  # ------------------------------------------------------------

  describe "obtener_categoria/1" do
    test "retorna {:ok, categoria} si existe", %{file: _file} do
      categoria = categoria_base()
      CategoryStore.guardar_categoria(categoria)

      assert {:ok, encontrada} = CategoryStore.obtener_categoria(categoria.id)
      assert encontrada.id == categoria.id
      assert encontrada.nombre == categoria.nombre
    end

    test "retorna nil si no existe" do
      assert CategoryStore.obtener_categoria("x999") == nil
    end
  end

  # ------------------------------------------------------------
  # listar_categorias/0
  # ------------------------------------------------------------

  describe "listar_categorias/0" do
    test "retorna lista vacía si el archivo sólo contiene encabezado", %{file: _file} do
      assert CategoryStore.listar_categorias() == []
    end

    test "lista todas las categorías registradas", %{file: _file} do
      c1 = categoria_base(id: "c1", nombre: "Backend")
      c2 = categoria_base(id: "c2", nombre: "Frontend")

      CategoryStore.guardar_categoria(c1)
      CategoryStore.guardar_categoria(c2)

      categorias = CategoryStore.listar_categorias()

      assert length(categorias) == 2
      assert Enum.any?(categorias, &(&1.nombre == "Backend"))
      assert Enum.any?(categorias, &(&1.nombre == "Frontend"))
    end
  end

  # ------------------------------------------------------------
  # eliminar_categoria/1
  # ------------------------------------------------------------

  describe "eliminar_categoria/1" do
    test "elimina una categoría existente por nombre", %{file: _file} do
      categoria = categoria_base(nombre: "Videojuegos")
      CategoryStore.guardar_categoria(categoria)

      assert :ok == CategoryStore.eliminar_categoria("Videojuegos")

      categorias = CategoryStore.listar_categorias()
      refute Enum.any?(categorias, &(&1.nombre == "Videojuegos"))
    end

    test "si no existe, no altera el archivo", %{file: _file} do
      c1 = categoria_base(nombre: "Salud")
      CategoryStore.guardar_categoria(c1)

      CategoryStore.eliminar_categoria("Inexistente")

      categorias = CategoryStore.listar_categorias()
      assert length(categorias) == 1
      assert hd(categorias).nombre == "Salud"
    end
  end

  # ------------------------------------------------------------
  # PARSEO Y SERIALIZACIÓN
  # ------------------------------------------------------------

  describe "serialización y parsing interno" do
    test "las categorías se guardan y cargan iguales", %{file: _file} do
      original =
        categoria_base(
          id: "test001",
          nombre: "Seguridad",
          descripcion: "Criptografía",
          proyectos: ["p1", "p2", "p3"],
          activo: true
        )

      CategoryStore.guardar_categoria(original)

      {:ok, cargada} = CategoryStore.obtener_categoria("test001")

      assert cargada.id == original.id
      assert cargada.nombre == original.nombre
      assert cargada.descripcion == original.descripcion
      assert cargada.proyectos == original.proyectos
      assert cargada.creador_id == original.creador_id
      assert cargada.activo == original.activo
    end

    test "parsea correctamente fechas inválidas sustituyéndolas por utc_now()", %{file: file} do
      contenido =
        @encabezado <>
        "c10,Cat,Desc,p1;p2,fecha_x,user1,true\n"

      File.write!(file, contenido)

      [categoria] = CategoryStore.listar_categorias()

      assert %DateTime{} = categoria.fecha_creacion
    end
  end
end
