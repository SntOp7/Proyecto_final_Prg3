defmodule ProyectoFinalPrg3.Adapters.Persistence.FeedbackStoreTest do
  use ExUnit.Case, async: false

  alias ProyectoFinalPrg3.Adapters.Persistence.FeedbackStore
  alias ProyectoFinalPrg3.Domain.Feedback

  @data_dir Path.join([File.cwd!(), "data"])
  @csv_file Path.join(@data_dir, "feedback.csv")

  # ============================================================
  # CONFIGURACIÓN DE ENTORNO AISLADO DE PRUEBAS
  # ============================================================

  setup do
    File.rm_rf!(@data_dir)
    File.mkdir_p!(@data_dir)

    # Crear archivo vacío con encabezado obligatorio
    File.write!(@csv_file, FeedbackStore.@headers)

    :ok
  end

  # ============================================================
  # UTILIDADES PARA CREAR FEEDBACKS DE PRUEBA
  # ============================================================

  defp fb(attrs \\ %{}) do
    %Feedback{
      id: Map.get(attrs, :id, "F1"),
      mentor_id: Map.get(attrs, :mentor_id, "M1"),
      proyecto_id: Map.get(attrs, :proyecto_id, "P1"),
      equipo_id: Map.get(attrs, :equipo_id, "E1"),
      avance_id: Map.get(attrs, :avance_id, "A1"),
      contenido: Map.get(attrs, :contenido, "Texto base"),
      fecha_creacion: Map.get(attrs, :fecha_creacion, DateTime.utc_now()),
      nivel: Map.get(attrs, :nivel, "info"),
      visibilidad: Map.get(attrs, :visibilidad, "publico"),
      estado: Map.get(attrs, :estado, "pendiente")
    }
  end

  # ============================================================
  # PRUEBAS CRUD
  # ============================================================

  describe "guardar_feedback/1" do
    test "crea un nuevo feedback y lo almacena en CSV" do
      f = fb(contenido: "Excelente avance")

      {:ok, _} = FeedbackStore.guardar_feedback(f)

      contenido = File.read!(@csv_file)
      assert contenido =~ "Excelente avance"
      assert contenido =~ "publico"
    end

    test "actualiza un feedback existente sin duplicarlo" do
      f1 = fb(id: "A100", contenido: "Versión 1")
      f2 = fb(id: "A100", contenido: "Versión 2")

      FeedbackStore.guardar_feedback(f1)
      FeedbackStore.guardar_feedback(f2)

      contenido = File.read!(@csv_file)
      assert contenido =~ "Versión 2"
      refute contenido =~ "Versión 1"
    end
  end

  describe "obtener_feedback/1" do
    test "retorna {:error, :no_encontrado} si no existe" do
      assert FeedbackStore.obtener_feedback("ZZZ") == {:error, :no_encontrado}
    end

    test "retorna {:ok, feedback} si existe" do
      f = fb(id: "B200", contenido: "Buen trabajo", nivel: "elogio")
      FeedbackStore.guardar_feedback(f)

      {:ok, encontrado} = FeedbackStore.obtener_feedback("B200")
      assert encontrado.id == "B200"
      assert encontrado.contenido == "Buen trabajo"
      assert encontrado.nivel == "elogio"
    end
  end

  describe "listar_feedbacks/0" do
    test "retorna lista vacía si el archivo no tiene contenido" do
      File.write!(@csv_file, FeedbackStore.@headers)
      assert FeedbackStore.listar_feedbacks() == []
    end

    test "lista correctamente los feedbacks guardados" do
      f = fb(id: "C300", contenido: "Documentación excelente")
      FeedbackStore.guardar_feedback(f)

      lista = FeedbackStore.listar_feedbacks()
      assert length(lista) == 1
      assert hd(lista).id == "C300"
    end
  end

  describe "eliminar_feedback/1" do
    test "elimina un feedback existente" do
      f = fb(id: "DEL", contenido: "Eliminarme")
      FeedbackStore.guardar_feedback(f)

      :ok = FeedbackStore.eliminar_feedback("DEL")
      contenido = File.read!(@csv_file)

      refute contenido =~ "Eliminarme"
      refute contenido =~ "DEL"
    end
  end

  # ============================================================
  # FILTRADO Y CONSULTAS
  # ============================================================

  describe "listar_por_mentor/1" do
    test "retorna feedbacks emitidos por un mentor específico" do
      f1 = fb(id: "1", mentor_id: "M100", contenido: "Uno")
      f2 = fb(id: "2", mentor_id: "M200", contenido: "Dos")

      FeedbackStore.guardar_feedback(f1)
      FeedbackStore.guardar_feedback(f2)

      results = FeedbackStore.listar_por_mentor("M100")

      assert Enum.count(results) == 1
      assert Enum.all?(results, &(&1.mentor_id == "M100"))
    end
  end

  describe "listar_por_destino/1" do
    test "retorna feedbacks asociados a proyecto o equipo" do
      f = fb(id: "X", proyecto_id: "PRJ9", contenido: "Destino test")
      FeedbackStore.guardar_feedback(f)

      results = FeedbackStore.listar_por_destino("PRJ9")
      assert Enum.any?(results, &(&1.proyecto_id == "PRJ9"))
    end
  end

  describe "filtrar_por/2" do
    test "filtra correctamente por estado, nivel y visibilidad" do
      f1 = fb(id: "A", nivel: "alto", visibilidad: "publico", estado: "abierto")
      f2 = fb(id: "B", nivel: "bajo", visibilidad: "privado", estado: "cerrado")

      FeedbackStore.guardar_feedback(f1)
      FeedbackStore.guardar_feedback(f2)

      assert Enum.all?(FeedbackStore.filtrar_por(:nivel, "alto"), &(&1.nivel == "alto"))
      assert Enum.all?(FeedbackStore.filtrar_por(:visibilidad, "privado"), &(&1.visibilidad == "privado"))
      assert Enum.all?(FeedbackStore.filtrar_por(:estado, "cerrado"), &(&1.estado == "cerrado"))
    end
  end

  # ============================================================
  # VALIDACIÓN DE PARSEO Y SERIALIZACIÓN
  # ============================================================

  describe "funciones internas de serialización y parseo" do
    test "parse_csv_line construye correctamente un struct Feedback" do
      dt = DateTime.utc_now() |> DateTime.to_iso8601()
      linea = "10,MX,PX,EX,AX,Mensaje,#{dt},medio,publico,ok"

      result = :erlang.apply(FeedbackStore, :parse_csv_line, [linea])

      assert result.id == "10"
      assert result.mentor_id == "MX"
      assert result.contenido == "Mensaje"
      assert result.visibilidad == "publico"
      assert result.estado == "ok"
    end

    test "sanitize elimina comas e interlineados" do
      input = "Hola, mundo\notro"
      result = :erlang.apply(FeedbackStore, :sanitize, [input])

      assert result == "Hola; mundo otro"
    end

    test "parse_nil transforma cadena vacía en nil" do
      assert :erlang.apply(FeedbackStore, :parse_nil, [""]) == nil
      assert :erlang.apply(FeedbackStore, :parse_nil, ["valor"]) == "valor"
    end

    test "parse_datetime falla a nil cuando recibe formato inválido" do
      assert :erlang.apply(FeedbackStore, :parse_datetime, [""]) == nil
      assert :erlang.apply(FeedbackStore, :parse_datetime, ["invalido"]) == nil
    end

    test "format_datetime genera ISO8601 o vacío" do
      now = DateTime.utc_now()
      iso = :erlang.apply(FeedbackStore, :format_datetime, [now])

      assert String.contains?(iso, "T")
      assert :erlang.apply(FeedbackStore, :format_datetime, [nil]) == ""
    end
  end
end
