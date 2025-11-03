defmodule ProyectoFinalPrg3.Adapters.CLI.CommandExecutorTest do
  use ExUnit.Case, async: true
  import Mox

  alias ProyectoFinalPrg3.Adapters.CLI.CommandExecutor

  # ============================================================
  # CONFIGURACIÓN DE MOCKS
  # ============================================================
  setup :verify_on_exit!

  setup do
    # Mocks de dependencias
    stub_with(ProyectoFinalPrg3.Mocks.CommandServiceMock, ProyectoFinalPrg3.Services.CommandService)
    stub_with(ProyectoFinalPrg3.Mocks.LoggerServiceMock, ProyectoFinalPrg3.Adapters.Logging.LoggerService)
    :ok
  end

  describe "execute/2" do
    test "ejecuta correctamente un comando válido" do
      info = %{service: :command_service, action: :listar_equipos}
      args = []

      ProyectoFinalPrg3.Mocks.LoggerServiceMock
      |> expect(:registrar_evento, fn "Ejecución CLI", %{comando: ^info, args: ^args} -> :ok end)

      ProyectoFinalPrg3.Mocks.CommandServiceMock
      |> expect(:ejecutar_comando, fn ^info, ^args -> {:ok, "Comando ejecutado"} end)

      assert {:ok, "Comando ejecutado"} = CommandExecutor.execute(info, args)
    end

    test "retorna error si el formato de parámetros es inválido" do
      assert {:error, "Formato inválido de comando o argumentos."} =
               CommandExecutor.execute("invalid", :wrong)
    end

    test "maneja correctamente una excepción durante la ejecución del comando" do
      info = %{service: :command_service, action: :causar_error}
      args = ["test"]

      ProyectoFinalPrg3.Mocks.LoggerServiceMock
      |> expect(:registrar_evento, fn "Ejecución CLI", _ -> :ok end)
      |> expect(:registrar_evento, fn "Error en ejecución CLI", %{comando: ^info, error: _msg} ->
        :ok
      end)

      ProyectoFinalPrg3.Mocks.CommandServiceMock
      |> expect(:ejecutar_comando, fn ^info, ^args -> raise "fallo en ejecución" end)

      {:error, mensaje} = CommandExecutor.execute(info, args)
      assert String.contains?(mensaje, "Error al ejecutar el comando: fallo en ejecución")
    end
  end
end
