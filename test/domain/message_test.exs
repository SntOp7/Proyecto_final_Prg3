defmodule Proyecto_final_Prg3.Test.Domain.MessageTest do
  use ExUnit.Case, async: true
  alias Proyecto_final_Prg3.Domain.Message

  @moduledoc """
  Pruebas unitarias del dominio `Message`.

  Validan:
    - Integridad de la estructura `Message`.
    - Correcto funcionamiento del constructor `nuevo/11`.
    - Tipos de datos y relaciones entre remitente, canal y proyecto.
    - Compatibilidad con campos opcionales, listas y valores nulos.
  """

  describe "Estructura base del mensaje" do
    test "contiene todos los campos esperados" do
      campos = Map.keys(%Message{})
      esperados = [
        :id,
        :remitente_id,
        :canal_id,
        :contenido,
        :timestamp,
        :tipo,
        :adjunto_url,
        :equipo_id,
        :proyecto_id,
        :leido_por,
        :reacciones
      ]

      assert Enum.sort(campos) == Enum.sort(esperados)
    end
  end

  describe "Función nuevo/11" do
    setup do
      timestamp = ~N[2025-10-26 14:15:00]

      mensaje = Message.nuevo(
        1,
        5,
        20,
        "¡Hola equipo! Ya subí la última versión del código.",
        timestamp,
        "texto",
        nil,
        3,
        10,
        [5, 6, 7],
        ["👍", "🔥"]
      )

      %{mensaje: mensaje, timestamp: timestamp}
    end

    test "se inicializa correctamente con todos los campos", %{mensaje: m, timestamp: timestamp} do
      assert m.id == 1
      assert m.remitente_id == 5
      assert m.canal_id == 20
      assert String.contains?(m.contenido, "versión del código")
      assert m.timestamp == timestamp
      assert m.tipo == "texto"
      assert is_nil(m.adjunto_url)
      assert m.equipo_id == 3
      assert m.proyecto_id == 10
      assert Enum.count(m.leido_por) == 3
      assert Enum.member?(m.reacciones, "🔥")
    end

    test "permite valores nulos u opcionales" do
      m = Message.nuevo(
        2,
        7,
        nil,
        "Mensaje del sistema: canal cerrado.",
        ~N[2025-10-26 10:00:00],
        "sistema",
        nil,
        nil,
        nil,
        [],
        []
      )

      assert is_nil(m.canal_id)
      assert m.tipo == "sistema"
      assert m.reacciones == []
      assert m.leido_por == []
    end
  end

  describe "Validaciones básicas de datos" do
    test "el contenido debe ser una cadena válida" do
      m = Message.nuevo(3, 2, 1, "Notificación enviada", ~N[2025-10-26 09:00:00], "notificación", nil, nil, nil, [], [])
      assert is_binary(m.contenido)
      assert String.length(m.contenido) > 5
    end

    test "el tipo debe pertenecer a la lista de tipos válidos" do
      m = Message.nuevo(4, 1, 2, "Archivo adjunto", ~N[2025-10-26 12:00:00], "archivo", "https://archivo.com/img.png", nil, nil, [], [])
      assert m.tipo in ["texto", "archivo", "sistema", "notificación"]
    end

    test "la fecha debe ser de tipo NaiveDateTime" do
      m = Message.nuevo(5, 3, 5, "Mensaje prueba", ~N[2025-10-26 15:30:00], "texto", nil, nil, nil, [], [])
      assert match?(%NaiveDateTime{}, m.timestamp)
    end

    test "leido_por y reacciones deben ser listas" do
      m = Message.nuevo(6, 1, 2, "Hola", ~N[2025-10-26 10:00:00], "texto", nil, nil, nil, [1, 2], ["👍"])
      assert is_list(m.leido_por)
      assert is_list(m.reacciones)
    end
  end
end
