defmodule ProyectoFinalPrg3.Adapters.Network.NodeManager do
  @moduledoc """
  Servicio encargado de gestionar la comunicación entre **nodos distribuidos**
  del sistema. Funciona como el adaptador que permite enviar mensajes entre
  diferentes nodos en un clúster Erlang.

  Este módulo permite:
    - Difundir eventos a todos los nodos conectados.
    - Enviar mensajes directos a un nodo específico.
    - Registrar fallos de comunicación.
    - Verificar estado del clúster.

  Utilizado principalmente por:
    - `BroadcastService`
    - `SupervisionManager`
    - Servicio de replicación distribuida (cuando exista)

  Autores: [Sharif Giraldo, Juan Sebastián Hernández y Santiago Ospina Sánchez]
  Fecha: 2025-10-27
  Licencia: GNU GPLv3
  """

  alias ProyectoFinalPrg3.Adapters.Logging.LoggerService

  # ============================================================
  # API PÚBLICA
  # ============================================================

  @doc """
  Envía un mensaje a **todos los nodos conectados**.

  Si no hay nodos, simplemente retorna `:sin_nodos`.

  ## Ejemplo
      NodeManager.enviar_a_nodos(:evento, %{msg: "Hola"})
  """
  def enviar_a_nodos(evento, mensaje) do
    nodos = Node.list()

    if nodos == [] do
      LoggerService.registrar_evento("Difusión distribuida omitida: sin nodos", %{
        evento: evento
      })

      :sin_nodos
    else
      Enum.each(nodos, fn nodo ->
        enviar_directo(nodo, {evento, mensaje})
      end)

      :ok
    end
  end

  @doc """
  Envía un mensaje directo a un nodo en particular.

  Internamente utiliza `:rpc.call`, asegurando que:
    - No explota si el nodo está caído
    - Registra logs de error cuando falla
  """
  def enviar_directo(nodo, payload) when is_atom(nodo) do
    if nodo in Node.list() do
      respuesta = :rpc.call(nodo, __MODULE__, :recibir_mensaje, [payload])

      LoggerService.registrar_evento("Mensaje enviado a nodo", %{
        destino: nodo,
        payload: payload,
        respuesta: respuesta
      })

      :ok
    else
      LoggerService.registrar_evento("Error: nodo no está conectado", %{
        destino: nodo
      })

      {:error, :nodo_no_conectado}
    end
  end

  # ============================================================
  # RECEPCIÓN EN NODOS REMOTOS
  # ============================================================

  @doc """
  Función remota llamada vía RPC para recibir mensajes en un nodo externo.

  Esta función siempre debe ser pública, pues `:rpc.call/4`
  la ejecutará desde otro nodo.
  """
  def recibir_mensaje({evento, data}) do
    LoggerService.registrar_evento("Mensaje recibido desde otro nodo", %{
      evento: evento,
      data: data
    })

    {:ok, :recibido}
  end

  # ============================================================
  # UTILIDADES DE CLÚSTER
  # ============================================================

  @doc """
  Retorna información del estado del clúster:

    - nodo local
    - lista de nodos conectados
    - si el sistema está distribuido o no
  """
  def estado_cluster do
    %{
      nodo_local: Node.self(),
      nodos_conectados: Node.list(),
      distribuido?: Node.list() != []
    }
  end

  # ============================================================
  # INICIALIZACIÓN DEL NODO LOCAL
  # ============================================================

  @doc """
  Inicializa el nodo local en caso de que no esté iniciado.

  - Asigna el cookie de comunicación distribuida
  - Inicia un nodo con nombre si el proyecto no fue iniciado con --sname o --name

  Esta función es segura y NO genera errores si el nodo ya estaba iniciado.
  """
  def inicializar_nodo do
    case Node.alive?() do
      true ->
        # Nodo ya tiene nombre, solo asignar cookie.
        Node.set_cookie(Node.self(), :proyecto_final_cookie)

        LoggerService.registrar_evento("Nodo distribuido inicializado", %{
          nodo: Node.self()
        })

        :ok

      false ->
        # Nodo local sin nombre: inicializarlo correctamente.
        iniciar_nodo_con_nombre(nodo_generado())
    end
  end

  # Asigna un nombre real al nodo
  defp iniciar_nodo_con_nombre(nombre_atomico) when is_atom(nombre_atomico) do
    case Node.start(nombre_atomico) do
      {:ok, _} ->
        Node.set_cookie(nombre_atomico, :proyecto_final_cookie)

        LoggerService.registrar_evento("Nodo local iniciado", %{
          nodo: nombre_atomico
        })

        :ok

      {:error, razon} ->
        LoggerService.registrar_evento("No se pudo iniciar nodo", %{
          error: inspect(razon)
        })

        {:error, razon}
    end
  end

  # Genera un nombre único basado en timestamp y hostname
  defp nodo_generado do
    host =
      case :inet.gethostname() do
        {:ok, h} -> to_string(h)
        _ -> "localhost"
      end

    :"proyecto_final_#{System.system_time(:millisecond)}@#{host}"
  end

  # ============================================================
  # CONEXIÓN A NODOS DEL CLÚSTER
  # ============================================================

  @doc """
  Intenta conectarse a los nodos configurados en `config/config.exs`.

  Si no existen nodos o están apagados, simplemente se registran logs.
  """
  def conectarse_a_nodos do
    nodos = Application.get_env(:proyecto_final_prg3, :nodos, [])

    Enum.each(nodos, fn nodo ->
      case Node.connect(nodo) do
        true ->
          LoggerService.registrar_evento("Conectado a nodo", %{nodo: nodo})

        false ->
          LoggerService.registrar_evento("No se pudo conectar al nodo", %{
            nodo: nodo,
            estado: :rechazado
          })
      end
    end)

    :ok
  end
end
