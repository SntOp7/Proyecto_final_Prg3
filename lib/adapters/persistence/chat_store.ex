defmodule ProyectoFinalPrg3.Adapters.Persistence.ChatStore do
  @moduledoc """
  Almacena mensajes de chat por equipo usando ETS.
  """

  @table :chat_mensajes

  if :ets.whereis(@table) == :undefined do
    :ets.new(@table, [:named_table, :public, :bag])
  end

  @doc """
  Agrega un mensaje al chat de un equipo.
  """
  def agregar_mensaje(equipo, mensaje) do
    :ets.insert(@table, {equipo, mensaje})
    :ok
  end

  @doc """
  Obtiene los últimos N mensajes de un equipo.
  """
  def obtener_mensajes(equipo, limite \\ 50) do
    :ets.lookup(@table, equipo)
    |> Enum.map(fn {_eq, msg} -> msg end)
    |> Enum.sort_by(& &1.timestamp, {:desc, DateTime})
    |> Enum.take(limite)
    |> Enum.reverse()
  end

  @doc """
  Elimina todos los mensajes de un equipo.
  """
  def limpiar_chat(equipo) do
    :ets.match_delete(@table, {equipo, :_})
    :ok
  end
end
