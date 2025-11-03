defmodule ProyectoFinalPrg3.Adapters.Persistence.FeedbackStoreTest do
  use ExUnit.Case, async: false

  alias ProyectoFinalPrg3.Adapters.Persistence.FeedbackStore
  alias ProyectoFinalPrg3.Domain.Feedback

  @data_dir Path.join(File.cwd!(), "tmp/feedback_data")
  @csv_file Path.join(@data_dir, "feedback.csv")

  setup do
    File.rm_rf!(@data_dir)
    File.mkdir_p!(@data_dir)
    # Simulamos la ruta de archivo
    Application.put_env(:proyecto_final_prg3, :feedback_csv_path, @csv_file)
    :ok
  end

  # ============================================================
  # PRUEBAS CRUD
  # ============================================================

  describe "guardar_feedback/1" do
    test "crea un nuevo feedback y genera el archivo CSV" do
      fb = %Feedback{
        id: "1",
        mentor_id: "M1",
        proyecto_id: "P1",
        equipo_id: "E1",
        avance_id: "A1",
        contenido: "Excelente avance.",
        fecha_creacion: DateTime.utc_now(),
        nivel: "informativo",
        visibilidad: "publico",
        estado: "pendiente"
      }

      {:ok, _} = FeedbackStore.guardar_feedback(fb)
      assert File.exists?("data/feedback.csv")

      contenido = File.read!("data/feedback.csv")
      assert contenido =~ "Excelente avance"
      assert contenido =~ "informativo"
    end

    test "actualiza un feedback existente en lugar de duplicarlo" do
      fb1 = %Feedback{
        id: "X1",
        mentor_id: "M1",
        proyecto_id: "P1",
        equipo_id: "E1",
        avance_id: "A1",
        contenido: "Versión inicial",
        fecha_creacion: DateTime.utc_now(),
        nivel: "informativo",
        visibilidad: "privado",
        estado: "pendiente"
      }

      fb2 = %{fb1 | contenido: "Versión actualizada"}

      {:ok, _} = FeedbackStore.guardar_feedback(fb1)
      {:ok, _} = FeedbackStore.guardar_feedback(fb2)

      contenido = File.read!("data/feedback.csv")
      assert String.contains?(contenido, "Versión actualizada")
      refute String.contains?(contenido, "Versión inicial")
    end
  end

  describe "obtener_feedback/1" do
    test "retorna {:error, :no_encontrado} si no existe" do
      assert FeedbackStore.obtener_feedback("NOPE") == {:error, :no_encontrado}
    end

    test "retorna {:ok, feedback} si existe en CSV" do
      fb = %Feedback{
        id: "100",
        mentor_id: "M5",
        proyecto_id: "P9",
        equipo_id: "E9",
        avance_id: "A9",
        contenido: "Buen trabajo",
        fecha_creacion: DateTime.utc_now(),
        nivel: "elogio",
        visibilidad: "publico",
        estado: "cerrado"
      }

      {:ok, _} = FeedbackStore.guardar_feedback(fb)
      {:ok, encontrado} = FeedbackStore.obtener_feedback("100")

      assert encontrado.id == "100"
      assert encontrado.contenido == "Buen trabajo"
      assert encontrado.nivel == "elogio"
    end
  end

  describe "listar_feedbacks/0" do
    test "retorna lista vacía si el archivo no existe" do
      File.rm_rf!("data")
      assert FeedbackStore.listar_feedbacks() == []
    end

    test "retorna lista de feedbacks válidos si el archivo existe" do
      fb = %Feedback{
        id: "200",
        mentor_id: "M2",
        proyecto_id: "P2",
        equipo_id: "E2",
        avance_id: "A2",
        contenido: "Excelente documentación",
        fecha_creacion: DateTime.utc_now(),
        nivel: "elogio",
        visibilidad: "publico",
        estado: "cerrado"
      }

      {:ok, _} = FeedbackStore.guardar_feedback(fb)
      lista = FeedbackStore.listar_feedbacks()

      assert length(lista) == 1
      assert Enum.any?(lista, &(&1.id == "200"))
    end
  end

  describe "eliminar_feedback/1" do
    test "elimina un feedback existente" do
      fb = %Feedback{
        id: "DEL",
        mentor_id: "MDEL",
        proyecto_id: "PDEL",
        equipo_id: "EDEL",
        avance_id: "ADEL",
        contenido: "Eliminarme",
        fecha_creacion: DateTime.utc_now(),
        nivel: "informativo",
        visibilidad: "privado",
        estado: "pendiente"
      }

      {:ok, _} = FeedbackStore.guardar_feedback(fb)
      :ok = FeedbackStore.eliminar_feedback("DEL")

      contenido = File.read!("data/feedback.csv")
      refute String.contains?(contenido, "Eliminarme")
    end
  end

  # ============================================================
  # FILTRADO Y CONSULTA
  # ============================================================

  describe "listar_por_mentor/1" do
    test "retorna feedbacks del mentor específico" do
      fb1 = %Feedback{id: "1", mentor_id: "M1", proyecto_id: "P1", equipo_id: nil, avance_id: nil,
        contenido: "uno", fecha_creacion: DateTime.utc_now(), nivel: "n1", visibilidad: "v1", estado: "e1"}
      fb2 = %{fb1 | id: "2", mentor_id: "M2", contenido: "dos"}

      {:ok, _} = FeedbackStore.guardar_feedback(fb1)
      {:ok, _} = FeedbackStore.guardar_feedback(fb2)

      result = FeedbackStore.listar_por_mentor("M1")
      assert Enum.all?(result, &(&1.mentor_id == "M1"))
    end
  end

  describe "listar_por_destino/1" do
    test "retorna feedbacks por proyecto o equipo id" do
      fb = %Feedback{
        id: "777",
        mentor_id: "MM",
        proyecto_id: "PR",
        equipo_id: nil,
        avance_id: nil,
        contenido: "Mensaje destino",
        fecha_creacion: DateTime.utc_now(),
        nivel: "info",
        visibilidad: "publico",
        estado: "ok"
      }

      {:ok, _} = FeedbackStore.guardar_feedback(fb)
      result = FeedbackStore.listar_por_destino("PR")

      assert Enum.any?(result, &(&1.proyecto_id == "PR"))
    end
  end

  describe "filtrar_por/2" do
    test "filtra por campo estado, nivel o visibilidad" do
      fb1 = %Feedback{id: "1", mentor_id: "M1", proyecto_id: "P1", equipo_id: nil, avance_id: nil,
        contenido: "uno", fecha_creacion: DateTime.utc_now(), nivel: "n1", visibilidad: "v1", estado: "e1"}

      fb2 = %{fb1 | id: "2", nivel: "n2", visibilidad: "v2", estado: "e2"}
      {:ok, _} = FeedbackStore.guardar_feedback(fb1)
      {:ok, _} = FeedbackStore.guardar_feedback(fb2)

      assert Enum.all?(FeedbackStore.filtrar_por(:estado, "e1"), &(&1.estado == "e1"))
      assert Enum.all?(FeedbackStore.filtrar_por(:nivel, "n2"), &(&1.nivel == "n2"))
      assert Enum.all?(FeedbackStore.filtrar_por(:visibilidad, "v1"), &(&1.visibilidad == "v1"))
    end
  end

  # ============================================================
  # FUNCIONES AUXILIARES PRIVADAS
  # ============================================================

  describe "funciones privadas de parseo y formato" do
    test "parse_csv_line convierte una línea CSV a struct válida" do
      now = DateTime.utc_now() |> DateTime.to_iso8601()
      linea = "1,M1,P1,E1,A1,Texto,#{now},info,publico,pendiente"
      result = :erlang.apply(FeedbackStore, :parse_csv_line, [linea])
      assert result.id == "1"
      assert result.contenido == "Texto"
      assert result.visibilidad == "publico"
    end

    test "sanitize reemplaza comas y saltos de línea" do
      input = "Hola, mundo\nnuevo"
      result = :erlang.apply(FeedbackStore, :sanitize, [input])
      assert result == "Hola; mundo nuevo"
    end

    test "parse_nil convierte cadena vacía en nil" do
      assert :erlang.apply(FeedbackStore, :parse_nil, [""]) == nil
      assert :erlang.apply(FeedbackStore, :parse_nil, ["valor"]) == "valor"
    end

    test "parse_datetime retorna nil si formato es inválido" do
      assert :erlang.apply(FeedbackStore, :parse_datetime, [""]) == nil
      assert :erlang.apply(FeedbackStore, :parse_datetime, ["invalido"]) == nil
    end

    test "format_datetime convierte DateTime a ISO8601 o cadena vacía" do
      now = DateTime.utc_now()
      iso = :erlang.apply(FeedbackStore, :format_datetime, [now])
      assert is_binary(iso)
      assert String.contains?(iso, "T")
      assert :erlang.apply(FeedbackStore, :format_datetime, [nil]) == ""
    end
  end
end
