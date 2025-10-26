defmodule Proyecto_final_Prg3.Test.Domain.ParticipantTest do
  use ExUnit.Case, async: true
  alias Proyecto_final_Prg3.Domain.Participant

  @moduledoc """
  Pruebas unitarias del dominio `Participant`.

  Se valida:
    - Creación correcta de estructuras.
    - Funcionamiento de la función `nuevo/14`.
    - Presencia de todos los campos definidos.
    - Coherencia de tipos y datos asignados.
  """

  describe "Estructura base del participante" do
    test "tiene todos los campos esperados" do
      campos = Map.keys(%Participant{})
      esperados = [
        :id,
        :nombre,
        :correo,
        :username,
        :rol,
        :equipo_id,
        :experiencia,
        :fecha_registro,
        :estado,
        :ultima_conexion,
        :mensajes,
        :canales_asignados,
        :token_sesion,
        :perfil_url
      ]

      assert Enum.sort(campos) == Enum.sort(esperados)
    end
  end

  describe "Función nuevo/14" do
    setup do
      fecha_registro = ~N[2025-10-25 10:30:00]
      ultima_conexion = ~N[2025-10-25 15:00:00]

      participante = Participant.nuevo(
        1,
        "Sharif Giraldo",
        "sharif@hackathon.com",
        "sharifg",
        "líder",
        2,
        "Fullstack Developer con experiencia en Elixir",
        fecha_registro,
        :activo,
        ultima_conexion,
        ["Mensaje 1", "Mensaje 2"],
        ["general", "equipo_2"],
        "TOKEN123",
        "https://perfil.com/sharif"
      )

      %{participante: participante, fecha_registro: fecha_registro, ultima_conexion: ultima_conexion}
    end

    test "crea correctamente un participante con todos los atributos", ctx do
      p = ctx.participante

      assert p.id == 1
      assert p.nombre == "Sharif Giraldo"
      assert p.correo == "sharif@hackathon.com"
      assert p.username == "sharifg"
      assert p.rol == "líder"
      assert p.equipo_id == 2
      assert p.experiencia =~ "Fullstack"
      assert p.fecha_registro == ctx.fecha_registro
      assert p.estado == :activo
      assert p.ultima_conexion == ctx.ultima_conexion
      assert length(p.mensajes) == 2
      assert Enum.member?(p.canales_asignados, "general")
      assert p.token_sesion == "TOKEN123"
      assert String.starts_with?(p.perfil_url, "https://")
    end

    test "permite campos nulos opcionales" do
      p = Participant.nuevo(
        "P-10",
        "Juan Pérez",
        "juan@correo.com",
        "juanp",
        "participante",
        nil,
        nil,
        ~N[2025-10-25 09:00:00],
        :pendiente,
        nil,
        nil,
        [],
        nil,
        nil
      )

      assert p.equipo_id == nil
      assert p.experiencia == nil
      assert p.ultima_conexion == nil
      assert p.mensajes == nil or p.mensajes == []
    end
  end

  describe "Validaciones básicas de datos" do
    test "el correo contiene '@'" do
      p = Participant.nuevo(
        5,
        "Carlos Ruiz",
        "carlos@correo.com",
        "carlosr",
        "organizador",
        1,
        "Gestor de eventos",
        ~N[2025-10-25 12:00:00],
        :activo,
        nil,
        [],
        [],
        "TOKEN_ABC",
        nil
      )

      assert String.contains?(p.correo, "@")
    end

    test "el estado debe ser un átomo o cadena" do
      p1 = Participant.nuevo(1, "Test", "a@b.com", "usr", "rol", nil, nil, "", :activo, nil, [], [], nil, nil)
      p2 = Participant.nuevo(2, "Test", "a@b.com", "usr", "rol", nil, nil, "", "desconectado", nil, [], [], nil, nil)

      assert is_atom(p1.estado)
      assert is_binary(p2.estado)
    end
  end
end
