defmodule ProyectoFinalPrg3.Adapters.Persistence.PersistenceManagerTest do
  use ExUnit.Case, async: false

  alias ProyectoFinalPrg3.Adapters.Persistence.PersistenceManager

  #
  # Desactivamos llamadas reales al LoggerService
  # Reemplazándolo con un módulo temporal mínimo.
  #
  defmodule FakeLogger do
    def registrar_evento(_, _), do: :ok
  end

  setup do
    # Sobrescribimos LoggerService en tiempo de prueba
    Application.put_env(:proyecto_final_prg3, :logger_service, FakeLogger)

    File.rm_rf!("data")
    :ok
  end

  @csv_files [
    {"categorias.csv",
     "id,nombre,descripcion,proyectos,fecha_creacion,creador_id,activo"},
    {"feedback.csv",
     "id,mentor_id,proyecto_id,equipo_id,avance_id,contenido,fecha_creacion,nivel,visibilidad,estado"},
    {"mentores.csv",
     "id,nombre,correo,especialidad,biografia,equipos_asignados,disponibilidad,canal_mentoria_id,fecha_registro,retroalimentaciones,rol,activo"},
    {"participantes.csv",
     "id,nombre,correo,username,rol,equipo_id,experiencia,fecha_registro,estado,ultima_conexion,mensajes,canales_asignados,token_sesion,perfil_url"},
    {"progress.csv",
     "id,proyecto_id,equipo_id,titulo,descripcion,fecha_registro,autor_id,estado,retroalimentacion,adjuntos,version"},
    {"proyectos.csv",
     "id,nombre,descripcion,categoria,estado,fecha_creacion,fecha_actualizacion,equipo_id,mentor_id,avances,retroalimentaciones,repositorio_url,puntaje,visibilidad,tags"},
    {"equipos.csv",
     "id,nombre,descripcion,categoria,id_proyecto,id_mentor,participantes,fecha_creacion,estado,canal_chat_id,puntaje,historial"}
  ]

  # ============================================================
  # inicializar/0
  # ============================================================

  describe "inicializar/0" do
    test "crea carpeta data/" do
      refute File.exists?("data")
      PersistenceManager.inicializar()
      assert File.exists?("data")
    end

    test "crea todos los archivos CSV con encabezados correctos" do
      PersistenceManager.inicializar()

      Enum.each(@csv_files, fn {archivo, encabezado} ->
        ruta = Path.join(["data", archivo])
        assert File.exists?(ruta)

        primera_linea =
          ruta
          |> File.stream!()
          |> Enum.take(1)
          |> hd()
          |> String.trim()

        assert primera_linea == encabezado
      end)
    end
  end

  # ============================================================
  # verificar_integridad/0
  # ============================================================

  describe "verificar_integridad/0" do
    setup do
      PersistenceManager.inicializar()
      :ok
    end

    test "no modifica archivos válidos" do
      contenido_original =
        Enum.map(@csv_files, fn {archivo, _} ->
          ruta = Path.join(["data", archivo])
          {archivo, File.read!(ruta)}
        end)

      PersistenceManager.verificar_integridad()

      Enum.each(contenido_original, fn {archivo, contenido_prev} ->
        ruta = Path.join(["data", archivo])
        assert File.read!(ruta) == contenido_prev
      end)
    end

    test "repara encabezado incorrecto" do
      {archivo, encabezado_correcto} = hd(@csv_files)
      ruta = Path.join(["data", archivo])

      File.write!(ruta, "ENCABEZADO_MALO\nlinea1\nlinea2\n")

      PersistenceManager.verificar_integridad()

      primera_linea =
        ruta
        |> File.stream!()
        |> Enum.take(1)
        |> hd()
        |> String.trim()

      assert primera_linea == encabezado_correcto
    end

    test "recrea archivos faltantes" do
      {archivo, encabezado_correcto} = Enum.at(@csv_files, 3)
      ruta = Path.join(["data", archivo])

      File.rm!(ruta)
      refute File.exists?(ruta)

      PersistenceManager.verificar_integridad()
      assert File.exists?(ruta)

      primera_linea =
        ruta
        |> File.stream!()
        |> Enum.take(1)
        |> hd()
        |> String.trim()

      assert primera_linea == encabezado_correcto
    end
  end

  # ============================================================
  # encabezado_incorrecto?/2 — función privada
  # ============================================================

  describe "encabezado_incorrecto?/2" do
    test "detecta encabezado incorrecto" do
      {archivo, encabezado_correcto} = hd(@csv_files)
      ruta = Path.join(["data", archivo])

      File.write!(ruta, "BAD_HEADER\ncuerpo\n")

      assert :erlang.apply(PersistenceManager, :encabezado_incorrecto?, [ruta, encabezado_correcto])
    end

    test "acepta encabezado correcto" do
      {archivo, encabezado_correcto} = hd(@csv_files)
      ruta = Path.join(["data", archivo])

      File.write!(ruta, encabezado_correcto <> "\ncontenido\n")

      refute :erlang.apply(PersistenceManager, :encabezado_incorrecto?, [ruta, encabezado_correcto])
    end
  end
end
