defmodule ProyectoFinalPrg3.Adapters.CLI.CommandParserTest do
  use ExUnit.Case, async: true
  import Mox

  alias ProyectoFinalPrg3.Adapters.CLI.CommandParser

  setup :verify_on_exit!

  setup do
    stub_with(ProyectoFinalPrg3.Mocks.CommandRegistryMock, ProyectoFinalPrg3.Adapters.CLI.CommandRegistry)
    :ok
  end

  describe "parse/1" do
    test "retorna error si la entrada está vacía" do
      assert {:error, :entrada_vacia} = CommandParser.parse("")
    end

    test "retorna estructura válida cuando el comando existe en el registro" do
      ProyectoFinalPrg3.Mocks.CommandRegistryMock
      |> expect(:get, fn "/join" -> {:ok, %{nombre: "/join", descripcion: "Unirse a un equipo"}} end)

      assert %{command: "/join", args: ["EquipoPhoenix"]} = CommandParser.parse("/join EquipoPhoenix")
    end

    test "maneja comandos con múltiples argumentos correctamente" do
      ProyectoFinalPrg3.Mocks.CommandRegistryMock
      |> expect(:get, fn "/create_team" -> {:ok, %{nombre: "/create_team"}} end)

      result = CommandParser.parse("/create_team Equipo A Descripción Avanzada")
      assert %{command: "/create_team", args: ["Equipo", "A", "Descripción", "Avanzada"]} = result
    end

    test "retorna error si el comando no está registrado" do
      ProyectoFinalPrg3.Mocks.CommandRegistryMock
      |> expect(:get, fn "/unknown" -> {:error, :comando_no_encontrado} end)

      assert {:error, :comando_desconocido} = CommandParser.parse("/unknown argumento")
    end
  end
end
