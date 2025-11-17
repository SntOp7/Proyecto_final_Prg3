defmodule ProyectoFinalPrg3.Adapters.CLI.CommandParser do
  @moduledoc """
  Analizador de comandos ingresados por el usuario en la interfaz de línea de comandos (CLI).

  Este módulo toma la cadena de entrada escrita por el usuario, separa el comando principal
  (por ejemplo, `/join`, `/teams`, `/chat`) y sus argumentos, devolviendo una estructura
  estandarizada que puede ser procesada por el `CommandRouter` o el `CommandExecutor`.

  **Mejora**: Soporta valores con espacios usando comillas.

  Ejemplos:

      iex> CommandParser.parse("/join EquipoPhoenix")
      {:ok, %{command: "/join", args: %{equipo: "EquipoPhoenix"}}}

      iex> CommandParser.parse("/feedback proyecto=\"Mi Proyecto\" mensaje=\"Excelente trabajo\"")
      {:ok, %{command: "/feedback", args: %{proyecto: "Mi Proyecto", mensaje: "Excelente trabajo"}}}

      iex> CommandParser.parse("")
      {:error, :entrada_vacia}

  Autores: [Sharif Giraldo Obando, Juan Sebastián Hernández y Santiago Ospina Sánchez]
  Fecha de creación: 2025-11-16
  Fecha de última modificación: 2025-11-17
  Licencia: GNU GPL v3
  """

  alias ProyectoFinalPrg3.Adapters.CLI.CommandRegistry

  # ============================================================
  # FUNCIÓN PRINCIPAL
  # ============================================================

  @doc """
  Parsea una línea de entrada de texto y retorna un mapa con:
    - `:command` → el comando (ej. "/join")
    - `:args` → mapa de argumentos parseados (si existen)

  Retorna:
    - `{:ok, %{command: cmd, args: args}}` si el comando es válido.
    - `{:error, :entrada_vacia}` si el texto está vacío.
    - `{:error, :comando_desconocido}` si no existe en el registro.
  """
  def parse(input) when is_binary(input) do
    trimmed = String.trim(input)

    case trimmed do
      "" ->
        {:error, :entrada_vacia}

      line ->
        # Separar comando del resto
        [command | resto] = String.split(line, " ", parts: 2)

        case CommandRegistry.get(command) do
          {:ok, _cmd_info} ->
            # Parsear argumentos (con soporte de comillas)
            args = case resto do
              [] -> %{}
              [params_str] -> parse_args_with_quotes(params_str)
            end

            {:ok, %{command: command, args: args}}

          {:error, :comando_no_encontrado} ->
            {:error, :comando_desconocido}
        end
    end
  end

  # ============================================================
  # PARSEO DE ARGUMENTOS CON SOPORTE DE COMILLAS
  # ============================================================

  @doc """
  Parsea argumentos en formato clave=valor, soportando valores con espacios usando comillas.

  Ejemplos:
    - `proyecto=EcoTracker` → %{proyecto: "EcoTracker"}
    - `proyecto="Mi Proyecto"` → %{proyecto: "Mi Proyecto"}
    - `nombre="Juan José" correo=juan@mail.com` → %{nombre: "Juan José", correo: "juan@mail.com"}
  """
  def parse_args_with_quotes(args_str) do
    # Regex para capturar: clave="valor con espacios" o clave=valor
    ~r/(\w+)=(?:"([^"]*)"|([^\s]+))/
    |> Regex.scan(args_str)
    |> Enum.map(fn
      # Con comillas: ["match", "clave", "valor"]
      [_match, clave, valor] when valor != "" ->
        {String.to_atom(clave), valor}
      # Sin comillas pero captura en el tercer grupo
      [_match, clave, "", valor] ->
        {String.to_atom(clave), valor}
      # Fallback
      [_match, clave] ->
        {String.to_atom(clave), ""}
    end)
    |> Enum.filter(fn {_k, v} -> v != "" end)
    |> Map.new()
  end

  @doc """
  Mantiene compatibilidad con el parser antiguo (sin comillas).
  Deprecado: usar parse_args_with_quotes en su lugar.
  """
  def parse_args(args) do
    args
    |> Enum.map(&String.split(&1, "=", parts: 2))
    |> Enum.reduce(%{}, fn
      [key, value], acc -> Map.put(acc, String.to_atom(key), value)
      _, acc -> acc
    end)
  end
end
