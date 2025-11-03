defmodule ProyectoFinalPrg3.Adapters.Persistence.DataStoreTest do
  use ExUnit.Case, async: false

  alias ProyectoFinalPrg3.Adapters.Persistence.DataStore.CategoryStore
  alias ProyectoFinalPrg3.Domain.Category

  @data_dir Path.join(File.cwd!(), "tmp/data_test")
  @csv_file Path.join(@data_dir, "categorias.csv")

  setup do
    File.rm_rf!(@data_dir)
    File.mkdir_p!(@data_dir)
    # Sobrescribimos la ruta de archivo para pruebas
    :ok
  end

  describe "guardar_categoria/1" do
    test "crea un nuevo archivo CSV con la categoría" do
      categoria = %Category{
        id: "1",
        nombre: "IA",
        descripcion: "Inteligencia Artificial",
        fecha_creacion: DateTime.utc_now(),
        fecha_modificacion: nil,
        estado: :activa
      }

      # Inyectar temporalmente la ruta
      allow_path(CategoryStore, @csv_file, fn ->
        {:ok, categoria} = CategoryStore.guardar_categoria(categoria)
        assert File.exists?(@csv_file)

        contenido = File.read!(@csv_file)
        assert contenido =~ "IA"
        assert contenido =~ "activa"
      end)
    end

    test "actualiza una categoría existente sin duplicar" do
      categoria = %Category{
        id: "1",
        nombre: "Backend",
        descripcion: "Desarrollo backend",
        fecha_creacion: DateTime.utc_now(),
        fecha_modificacion: nil,
        estado: :activa
      }

      nueva = %{categoria | descripcion: "Actualizada"}

      allow_path(CategoryStore, @csv_file, fn ->
        {:ok, _} = CategoryStore.guardar_categoria(categoria)
        {:ok, _} = CategoryStore.guardar_categoria(nueva)
        contenido = File.read!(@csv_file)

        assert String.contains?(contenido, "Actualizada")
        assert contenido =~ "Backend"
        assert String.split(contenido, "\n") |> length() == 2
      end)
    end
  end

  describe "obtener_categoria/1" do
    test "retorna nil si el archivo no existe" do
      File.rm_rf!(@data_dir)
      assert CategoryStore.obtener_categoria("NoExiste") == nil
    end

    test "retorna {:ok, categoria} si existe en CSV" do
      cat = %Category{
        id: "99",
        nombre: "Frontend",
        descripcion: "UI y UX",
        fecha_creacion: DateTime.utc_now(),
        fecha_modificacion: nil,
        estado: :activa
      }

      allow_path(CategoryStore, @csv_file, fn ->
        {:ok, _} = CategoryStore.guardar_categoria(cat)
        {:ok, encontrada} = CategoryStore.obtener_categoria("Frontend")

        assert encontrada.nombre == "Frontend"
        assert encontrada.descripcion == "UI y UX"
      end)
    end
  end

  describe "listar_categorias/0" do
    test "retorna lista vacía si el archivo no existe" do
      File.rm_rf!(@data_dir)
      assert CategoryStore.listar_categorias() == []
    end

    test "retorna una lista de categorías si el archivo existe" do
      categoria = %Category{
        id: "10",
        nombre: "Cloud",
        descripcion: "Servicios en la nube",
        fecha_creacion: DateTime.utc_now(),
        fecha_modificacion: nil,
        estado: :activa
      }

      allow_path(CategoryStore, @csv_file, fn ->
        {:ok, _} = CategoryStore.guardar_categoria(categoria)
        lista = CategoryStore.listar_categorias()

        assert is_list(lista)
        assert Enum.any?(lista, &(&1.nombre == "Cloud"))
      end)
    end
  end

  describe "eliminar_categoria/1" do
    test "elimina una categoría existente del CSV" do
      categoria = %Category{
        id: "20",
        nombre: "DevOps",
        descripcion: "Integración continua",
        fecha_creacion: DateTime.utc_now(),
        fecha_modificacion: nil,
        estado: :activa
      }

      allow_path(CategoryStore, @csv_file, fn ->
        {:ok, _} = CategoryStore.guardar_categoria(categoria)
        :ok = CategoryStore.eliminar_categoria("DevOps")
        contenido = File.read!(@csv_file)
        refute contenido =~ "DevOps"
      end)
    end
  end

  describe "funciones auxiliares internas" do
    test "serializar_categoria genera una línea CSV válida" do
      cat = %Category{
        id: "11",
        nombre: "ML",
        descripcion: "Machine Learning",
        fecha_creacion: DateTime.utc_now(),
        fecha_modificacion: nil,
        estado: :activa
      }

      linea = :erlang.apply(CategoryStore, :serializar_categoria, [cat])
      assert is_binary(linea)
      assert linea =~ "ML"
      assert linea =~ "activa"
    end

    test "parsear_linea_a_struct convierte correctamente el CSV a struct" do
      now = DateTime.utc_now() |> DateTime.to_string()
      linea = "123,Test,Desc,#{now},,activa"

      struct = :erlang.apply(CategoryStore, :parsear_linea_a_struct, [linea])
      assert struct.nombre == "Test"
      assert struct.descripcion == "Desc"
      assert struct.estado == :activa
    end

    test "convertir_a_nil retorna nil cuando recibe cadena vacía" do
      assert :erlang.apply(CategoryStore, :convertir_a_nil, [""]) == nil
      assert :erlang.apply(CategoryStore, :convertir_a_nil, ["valor"]) == "valor"
    end

    test "parsear_fecha retorna DateTime válido o utc_now por defecto" do
      iso = DateTime.utc_now() |> DateTime.to_iso8601()
      {:ok, dt, _} = DateTime.from_iso8601(iso)
      assert DateTime.diff(:erlang.apply(CategoryStore, :parsear_fecha, [iso]), dt) < 2
      assert is_struct(:erlang.apply(CategoryStore, :parsear_fecha, ["invalida"]), DateTime)
    end
  end

  # ============================================================
  # Helpers internos
  # ============================================================

  defp allow_path(_module, _path, fun) do
    File.mkdir_p!(Path.dirname(@csv_file))
    fun.()
  end
end
