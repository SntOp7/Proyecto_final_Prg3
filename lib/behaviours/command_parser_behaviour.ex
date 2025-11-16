defmodule ProyectoFinalPrg3.Behaviours.CommandParserBehaviour do
  @callback parse(String.t()) :: map() | nil | {:error, term()}
end
