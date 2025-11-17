defmodule ProyectoFinalPrg3.Adapters.CLI.CommandParser do
  @moduledoc """
  Analizador de comandos ingresados por el usuario en la interfaz de línea de comandos (CLI).

  Este módulo toma la cadena de entrada escrita por el usuario, separa el comando principal
  (por ejemplo, `/join`, `/teams`, `/chat`) y sus argumentos, devolviendo una estructura
  estandarizada que puede ser procesada por el `CommandRouter` o el `CommandExecutor`.

  Si el comando no es válido o está vacío, se devuelve un error controlado.

  Ejemplo:

      iex> CommandParser.parse("/join EquipoPhoenix")
      {:ok, %{command: "/join", args: ["EquipoPhoenix"]}}

      iex> CommandParser.parse("")
      {:error, :entrada_vacia}

  Autores: [Sharif Giraldo Obando, Juan Sebastián Hernández y Santiago Ospina Sánchez]
  Fecha de creación: 2025-11-16
  Fecha de última modificación: 2025-11-16
  Licencia: GNU GPL v3
  """

  alias ProyectoFinalPrg3.Adapters.CLI.CommandRegistry

  # ============================================================
  # FUNCIÓN PRINCIPAL
  # ============================================================

  @doc """
  Parsea una línea de entrada de texto y retorna un mapa con:
    - `:command` → el comando (ej. "/join")
    - `:args` → lista de argumentos (si existen)

  Retorna:
    - `{:ok, %{command: cmd, args: args}}` si el comando es válido.
    - `{:error, :entrada_vacia}` si el texto está vacío.
    - `{:error, :comando_desconocido}` si no existe en el registro.
  """
  def parse(input) when is_binary(input) do
    case String.split(String.trim(input), " ", trim: true) do
      [] ->
        {:error, :entrada_vacia}

      [command | raw_args] ->
        case CommandRegistry.get(command) do
          {:ok, _cmd_info} ->
            {:ok, %{command: command, args: parse_args(raw_args)}}

          {:error, :comando_no_encontrado} ->
            {:error, :comando_desconocido}
        end
    end
  end

  @doc false
  defp parse_args(args) do
    args
    |> Enum.map(&String.split(&1, "=", parts: 2))
    |> Enum.reduce(%{}, fn
      [key, value], acc -> Map.put(acc, String.to_atom(key), value)
      _, acc -> acc
    end)
  end
end
