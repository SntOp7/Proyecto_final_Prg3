defmodule ProyectoFinalPrg3.Adapters.Persistence.PersistenceManagerTest do
  use ExUnit.Case, async: false

  alias ProyectoFinalPrg3.Adapters.Persistence.PersistenceManager

  # Se mockea el LoggerService para evitar escrituras reales
  import Mox
  setup :set_mox_global

  setup do
    File.rm_rf!("data")
    Mox.stub_with(
      ProyectoFinalPrg3.Adapters.Logging.LoggerService.Mock,
      ProyectoFinalPrg3.Adapters.Logging.LoggerService
    )

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
  # 1. inicializar/0
  # ============================================================

  describe "inicializar/0" do
    test "crea carpeta data/" do
      refute File.exists?("data")
      PersistenceManager.inicializar()
      assert File.exists?("data")
    end

    test "crea todos los archivos CSV con encabezados correctos" do
      PersistenceManager.inicializar()

      Enum.each(@csv_files, fn {nombre_archivo, encabezado} ->
        ruta = Path.join(["data", nombre_archivo])
        assert File.exists?(ruta)

        primera_linea =
          File.stream!(ruta)
          |> Enum.take(1)
          |> hd()
          |> String.trim()

        assert primera_linea == encabezado
      end)
    end
  end

  # ============================================================
  # 2. verificar_integridad/0
  # ============================================================

  describe "verificar_integridad/0" do
    setup do
      PersistenceManager.inicializar()
      :ok
    end

    test "no modifica archivos válidos" do
      contenido_original =
        Enum.map(@csv_files, fn {nombre, _} ->
          ruta = Path.join(["data", nombre])
          {nombre, File.read!(ruta)}
        end)

      PersistenceManager.verificar_integridad()

      Enum.each(contenido_original, fn {nombre, contenido_prev} ->
        ruta = Path.join(["data", nombre])
        contenido_post = File.read!(ruta)
        assert contenido_prev == contenido_post
      end)
    end

    test "repara encabezado incorrecto" do
      {archivo, encabezado_correcto} = hd(@csv_files)
      ruta = Path.join(["data", archivo])

      # Sobrescribe archivo con encabezado inválido
      File.write!(ruta, "ENCABEZADO_MALO\nfila1\fila2\n")

      PersistenceManager.verificar_integridad()

      primera_linea =
        File.stream!(ruta)
        |> Enum.take(1)
        |> hd()
        |> String.trim()

      assert primera_linea == encabezado_correcto
    end

    test "recrea archivos faltantes" do
      {archivo, encabezado_esperado} = Enum.at(@csv_files, 2)

      ruta = Path.join(["data", archivo])
      File.rm!(ruta)

      refute File.exists?(ruta)

      PersistenceManager.verificar_integridad()

      assert File.exists?(ruta)

      primera_linea =
        File.stream!(ruta)
        |> Enum.take(1)
        |> hd()
        |> String.trim()

      assert primera_linea == encabezado_esperado
    end
  end

  # ============================================================
  # 3. Funcionamiento privado: encabezado_incorrecto?/2
  # ============================================================

  describe "encabezado_incorrecto?/2 (privada)" do
    test "detecta encabezado incorrecto" do
      {archivo, encabezado_correcto} = hd(@csv_files)
      ruta = Path.join(["data", archivo])

      File.write!(ruta, "BAD HEADER\ncontenido\n")

      assert :erlang.apply(
               PersistenceManager,
               :encabezado_incorrecto?,
               [ruta, encabezado_correcto]
             )
    end

    test "acepta encabezado correcto" do
      {archivo, encabezado_correcto} = hd(@csv_files)
      ruta = Path.join(["data", archivo])

      File.write!(ruta, encabezado_correcto <> "\nresto\n")

      refute :erlang.apply(
               PersistenceManager,
               :encabezado_incorrecto?,
               [ruta, encabezado_correcto]
             )
    end
  end
end
