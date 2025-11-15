defmodule ProyectoFinalPrg3.Adapters.CLI.CommandRegistryTest do
  use ExUnit.Case, async: true

  alias ProyectoFinalPrg3.Adapters.CLI.CommandRegistry

  @expected_commands [
    "/teams",
    "/project",
    "/join",
    "/chat",
    "/create_team",
    "/assign_mentor",
    "/help"
  ]

  describe "all/0" do
    test "retorna todos los comandos registrados en el sistema" do
      commands = CommandRegistry.all()
      assert is_map(commands)
      assert Map.keys(commands) == @expected_commands
    end

    test "cada comando contiene las claves mínimas requeridas" do
      CommandRegistry.all()
      |> Enum.each(fn {cmd, info} ->
        assert is_map(info), "La definición del comando #{cmd} debe ser un mapa"

        assert Map.has_key?(info, :description),
               "Falta la clave :description en #{cmd}"

        assert Map.has_key?(info, :service),
               "Falta la clave :service en #{cmd}"

        assert Map.has_key?(info, :action),
               "Falta la clave :action en #{cmd}"

        # required_permission es opcional pero si existe debe ser átomo
        if Map.has_key?(info, :required_permission) do
          assert is_atom(info.required_permission),
                 "El permiso requerido en #{cmd} debe ser un átomo"
        end
      end)
    end
  end

  describe "get/1" do
    test "retorna {:ok, info} con datos válidos para un comando existente" do
      {:ok, data} = CommandRegistry.get("/join")

      assert data.description == "Unirse a un equipo existente"
      assert data.service == :team_manager
      assert data.action == :join_team
      assert data.required_permission == :unirse_equipo
    end

    test "retorna {:error, :comando_no_encontrado} para comandos inexistentes" do
      assert {:error, :comando_no_encontrado} = CommandRegistry.get("/no_existe")
    end

    test "la información retornada por get/1 coincide con la almacenada en all/0" do
      all = CommandRegistry.all()

      Enum.each(@expected_commands, fn cmd ->
        {:ok, info_from_get} = CommandRegistry.get(cmd)
        info_from_all = all[cmd]
        assert info_from_get == info_from_all
      end)
    end
  end

  describe "estructura de datos" do
    test "los servicios y acciones están definidos correctamente como átomos" do
      CommandRegistry.all()
      |> Enum.each(fn {cmd, info} ->
        assert is_atom(info.service),
               "El servicio del comando #{cmd} debe ser un átomo"

        assert is_atom(info.action),
               "La acción del comando #{cmd} debe ser un átomo"
      end)
    end

    test "las descripciones son cadenas legibles y suficientemente descriptivas" do
      CommandRegistry.all()
      |> Enum.each(fn {cmd, info} ->
        assert is_binary(info.description),
               "La descripción del comando #{cmd} debe ser una cadena"

        assert String.length(info.description) > 5,
               "La descripción del comando #{cmd} es demasiado corta"
      end)
    end

    test "si existe required_permission, este debe ser un átomo válido" do
      CommandRegistry.all()
      |> Enum.each(fn {cmd, info} ->
        if Map.has_key?(info, :required_permission) do
          assert is_atom(info.required_permission),
                 "El permiso requerido en #{cmd} debe ser un átomo si está definido"
        end
      end)
    end
  end
end
