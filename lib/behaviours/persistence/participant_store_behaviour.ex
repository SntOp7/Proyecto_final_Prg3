defmodule ProyectoFinalPrg3.Adapters.Persistence.ParticipantStoreBehaviour do
  @moduledoc false

  @callback guardar_participante(map()) :: {:ok, map()} | {:error, any()}
  @callback obtener_participante(String.t()) :: map() | nil
  @callback buscar_por_correo(String.t()) :: map() | nil
  @callback listar_participantes() :: [map()]
  @callback eliminar_participante(String.t()) :: :ok | {:error, any()}
  @callback actualizar_estado(String.t(), boolean()) :: :ok | {:error, any()}
end
