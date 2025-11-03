defmodule ProyectoFinalPrg3.Adapters.CLI.CommandRouterTest do
  use ExUnit.Case, async: true
  import Mox

  alias ProyectoFinalPrg3.Adapters.CLI.CommandRouter
  alias ProyectoFinalPrg3.Adapters.CLI.{CommandParser, CommandRegistry, CommandExecutor}
  alias ProyectoFinalPrg3.Adapters.Logging.LoggerService

  setup :verify_on_exit!

  describe "route/1 - validaciones básicas" do
    test "retorna error cuando la entrada está vacía" do
      assert {:error, msg} = CommandRouter.route("   ")
      assert msg =~ "No se ingresó ningún comando"
    end

    test "retorna error cuando el argumento no es binario" do
      assert {:error, msg} = CommandRouter.route(123)
      assert msg =~ "Entrada inválida"
    end
  end

  describe "route/1 - flujo exitoso" do
    setup do
      # Mocks del flujo completo
      expect(CommandParser, :parse, fn "/join EquipoX" ->
        %{command: "/join", args: ["EquipoX"]}
      end)

      expect(CommandRegistry, :get, fn "/join" ->
        {:ok, %{service: :team_manager, action: :join_team, description: "Unirse a un equipo existente"}}
      end)

      expect(CommandExecutor, :execute, fn %{service: :team_manager}, ["EquipoX"] ->
        {:ok, "Te uniste al equipo exitosamente"}
      end)

      expect(LoggerService, :registrar_evento, fn _titulo, _datos -> :ok end)

      :ok
    end

    test "ejecuta correctamente el comando y devuelve resultado esperado" do
      assert {:ok, "Te uniste al equipo exitosamente"} =
               CommandRouter.route("/join EquipoX")
    end
  end

  describe "route/1 - errores controlados" do
    test "retorna error si CommandParser devuelve nil" do
      expect(CommandParser, :parse, fn _ -> nil end)
      assert {:error, msg} = CommandRouter.route("/algo")
      assert msg =~ "Comando no reconocido"
    end

    test "retorna error si el comando no existe en CommandRegistry" do
      expect(CommandParser, :parse, fn "/xyz" -> %{command: "/xyz", args: []} end)
      expect(CommandRegistry, :get, fn "/xyz" -> {:error, :comando_no_encontrado} end)

      assert {:error, msg} = CommandRouter.route("/xyz")
      assert msg =~ "Comando no reconocido"
    end
  end

  describe "route/1 - manejo de excepciones" do
    setup do
      expect(CommandParser, :parse, fn "/falla" ->
        %{command: "/falla", args: []}
      end)

      expect(CommandRegistry, :get, fn "/falla" ->
        {:ok, %{service: :falla_service, action: :crash}}
      end)

      expect(CommandExecutor, :execute, fn _, _ ->
        raise "Falla simulada"
      end)

      expect(LoggerService, :registrar_evento, 2, fn _titulo, _datos -> :ok end)

      :ok
    end

    test "captura errores lanzados en ejecución de comandos" do
      assert {:error, msg} = CommandRouter.route("/falla")
      assert msg =~ "Ocurrió un error al ejecutar el comando"
    end
  end
end
