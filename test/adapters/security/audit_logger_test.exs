defmodule ProyectoFinalPrg3.Adapters.Security.AuditLoggerTest do
  use ExUnit.Case, async: true
  import ExUnit.CaptureIO

  alias ProyectoFinalPrg3.Adapters.Security.AuditLogger

  describe "registrar_auditoria/2" do
    test "imprime alertas en color rojo si el estado es ERROR" do
      evento = %{
        mensaje: "Falla crítica",
        estado: :error
      }

      salida =
        capture_io(:stderr, fn ->
          AuditLogger.registrar_auditoria("Test", evento)
        end)

      assert String.contains?(salida, "Falla crítica")
    end
  end

  describe "mostrar_en_consola/1" do
    test "muestra alerta de seguridad con estado ERROR" do
      evento = %{mensaje: "HACK DETECTADO", estado: :error}

      salida =
        capture_io(fn ->
          :erlang.apply(AuditLogger, :mostrar_en_consola, [evento])
        end)

      assert String.contains?(salida, "HACK DETECTADO")
    end

    test "muestra log normal si estado es OK" do
      evento = %{mensaje: "Todo bien", estado: :ok}

      salida =
        capture_io(fn ->
          :erlang.apply(AuditLogger, :mostrar_en_consola, [evento])
        end)

      assert String.contains?(salida, "Todo bien")
    end
  end
end
