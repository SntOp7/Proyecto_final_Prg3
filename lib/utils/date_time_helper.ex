defmodule ProyectoFinalPrg3.Utils.DateTimeHelper do
  @moduledoc """
  Helper para formatear fechas en zona horaria de Colombia (UTC-5).
  """

  @doc """
  Convierte DateTime UTC a hora de Colombia.
  """
  def to_colombia_time(%DateTime{} = dt) do
    DateTime.add(dt, -5 * 3600, :second)
  end

  @doc """
  Formato para chat: "14:30", "Ayer 14:30", o "15/11 14:30"
  """
  def formato_chat(%DateTime{} = dt) do
    ahora = DateTime.utc_now()
    dt_colombia = to_colombia_time(dt)
    ahora_colombia = to_colombia_time(ahora)

    cond do
      # Hoy
      Date.compare(DateTime.to_date(dt_colombia), DateTime.to_date(ahora_colombia)) == :eq ->
        Calendar.strftime(dt_colombia, "%H:%M")

      # Ayer
      Date.diff(DateTime.to_date(ahora_colombia), DateTime.to_date(dt_colombia)) == 1 ->
        "Ayer " <> Calendar.strftime(dt_colombia, "%H:%M")

      # Más días
      true ->
        Calendar.strftime(dt_colombia, "%d/%m %H:%M")
    end
  end
end
