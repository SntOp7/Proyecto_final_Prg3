defmodule ProyectoFinalPrg3.Adapters.Network.ChannelManager do
  @moduledoc """
  Adaptador encargado de manejar la comunicación entre módulos a través de
  **canales internos** del sistema.

  Este adaptador no utiliza Phoenix Channels (websockets), sino una capa
  ligera basada en PubSub para comunicación interna entre procesos.

  Es utilizado principalmente por:

    - `BroadcastService`
    - `ChatService`
    - `MentorManager`
    - `TeamManager`

  ## Funciones principales
    - `broadcast/2`: Envía un mensaje a todos los procesos suscritos.
    - `enviar/2`: Envía un mensaje a un destino específico (PID o etiqueta lógica).

  Autores: [Sharif Giraldo Obando, Juan Sebastián Hernández y Santiago Ospina Sánchez]
  Fecha de creación: 2025-11-16
  Fecha de última modificación: 2025-11-16
  Licencia: GNU GPL v3
  """

  alias ProyectoFinalPrg3.Adapters.Network.PubSubAdapter
  alias ProyectoFinalPrg3.Adapters.Logging.LoggerService

  @doc """
  Envía un mensaje a **todos los suscritos** al evento o canal especificado.

  ## Ejemplo
      ChannelManager.broadcast(:equipo_actualizado, %{equipo: "Rocket"})
  ## Parámetros:
    - `canal`: Átomo que identifica el canal o evento.
    - `mensaje`: Cualquier estructura de datos que represente el mensaje.
  ## Retorna:
    - `:ok` – mensaje difundido con éxito.
  """
  def broadcast(canal, mensaje) when is_atom(canal) do
    PubSubAdapter.publicar(canal, mensaje)
    LoggerService.registrar_evento("Broadcast realizado", %{canal: canal, mensaje: mensaje})
    :ok
  end

  @doc """
  Envía un mensaje a un destino específico.
  El destino puede ser:

    - un PID (proceso)
    - un nombre de canal lógico como string o átomo

  ## Ejemplo
      ChannelManager.enviar(self(), %{msg: "Hola"})
      ChannelManager.enviar("equipo:123", %{msg: "Evento"})
  ## Parámetros:
    - `destino`: PID o etiqueta lógica (string/átomo).
    - `mensaje`: Cualquier estructura de datos que represente el mensaje.
  ## Retorna:
    - `:ok` – mensaje enviado con éxito.
  """
  def enviar(destino, mensaje)

  # Caso 1: destino es un proceso
  def enviar(destino, mensaje) when is_pid(destino) do
    send(destino, {:mensaje, mensaje})

    LoggerService.registrar_evento("Mensaje enviado a PID", %{
      pid: inspect(destino),
      mensaje: mensaje
    })

    :ok
  end

  # Caso 2: destino es un canal lógico (delegate a PubSub)
  def enviar(destino, mensaje) when is_atom(destino) or is_binary(destino) do
    PubSubAdapter.publicar(destino, mensaje)

    LoggerService.registrar_evento("Mensaje enviado a canal", %{
      canal: destino,
      mensaje: mensaje
    })

    :ok
  end
end
