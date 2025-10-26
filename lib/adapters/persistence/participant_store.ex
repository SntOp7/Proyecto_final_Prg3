defmodule ProyectoFinalPrg3.Adapters.Persistence.ParticipantStore do
  @moduledoc """
  Módulo encargado de la persistencia de datos de los participantes en el sistema.
  Implementa operaciones CRUD sobre un archivo CSV ubicado en la carpeta `data/participants.csv`.

  Este adaptador sirve como puente entre la capa de servicios (`ParticipantManager`)
  y el almacenamiento físico, manteniendo el principio de independencia de la lógica de negocio.

  Autores: [Sharif Giraldo, Juan Sebastián Hernández y Santiago Ospina Sánchez]
  Fecha de creación: 2025-10-26
  Licencia: GNU GPLv3
  """

  alias ProyectoFinalPrg3.Domain.Participant

  @ruta_archivo Path.join([File.cwd!(), "data", "participantes.csv"])
  @headers "id,nombre,correo,contrasena,rol,equipo_id,sesion_activa\n"

  # ============================================================
  # FUNCIONES PRINCIPALES CRUD
  # ============================================================

  @doc """
  Guarda o actualiza un participante en el archivo CSV.
  Si el participante ya existe, se reemplaza su información.
  """
  def guardar_participante(%Participant{} = participante) do
    participantes =
      listar_participantes()
      |> Enum.reject(&(&1.id == participante.id))
      |> Kernel.++([participante])

    escribir_participantes(participantes)
    {:ok, participante}
  end

  @doc """
  Obtiene un participante a partir de su identificador único.
  Retorna `nil` si no existe.
  """
  def obtener_participante(id) do
    listar_participantes()
    |> Enum.find(fn p -> p.id == id end)
  end

  @doc """
  Busca un participante por su correo electrónico.
  """
  def buscar_por_correo(correo) do
    listar_participantes()
    |> Enum.find(fn p -> p.correo == correo end)
  end

  @doc """
  Lista todos los participantes registrados en el archivo CSV.
  """
  def listar_participantes do
    if File.exists?(@data_path) do
      File.stream!(@data_path)
      |> Stream.drop(1)
      |> Stream.map(&parse_csv_line/1)
      |> Enum.to_list()
    else
      []
    end
  end

  @doc """
  Elimina un participante del sistema a partir de su ID.
  """
  def eliminar_participante(id) do
    participantes_filtrados =
      listar_participantes()
      |> Enum.reject(fn p -> p.id == id end)

    escribir_participantes(participantes_filtrados)
    :ok
  end

  @doc """
  Actualiza el estado de sesión (`true` o `false`) de un participante.
  """
  def actualizar_estado(id, sesion_activa) when is_boolean(sesion_activa) do
    with %Participant{} = participante <- obtener_participante(id) do
      actualizado = %{participante | sesion_activa: sesion_activa}
      guardar_participante(actualizado)
    else
      nil -> {:error, :no_encontrado}
    end
  end

  # ============================================================
  # FUNCIONES PRIVADAS DE SERIALIZACIÓN Y DESERIALIZACIÓN
  # ============================================================

  # Convierte una línea del CSV a una estructura %Participant{}
  defp parse_csv_line(line) do
    [id, nombre, correo, contrasena, rol, equipo_id, sesion_str] =
      line
      |> String.trim()
      |> String.split(",", parts: 7)

    %Participant{
      id: id,
      nombre: nombre,
      correo: correo,
      contrasena: contrasena,
      rol: rol,
      equipo_id: parse_nil(equipo_id),
      sesion_activa: parse_bool(sesion_str)
    }
  end

  # Escribe la lista de participantes al archivo CSV
  defp escribir_participantes(participantes) do
    contenido =
      participantes
      |> Enum.map(&to_csv_line/1)
      |> Enum.join("\n")

    File.mkdir_p!("data")
    File.write!(@data_path, @headers <> contenido)
  end

  # Convierte un participante en una línea CSV
  defp to_csv_line(%Participant{} = p) do
    [
      p.id,
      sanitize(p.nombre),
      p.correo,
      p.contrasena || "",
      p.rol,
      p.equipo_id || "",
      to_string(p.sesion_activa)
    ]
    |> Enum.join(",")
  end

  # ============================================================
  # FUNCIONES AUXILIARES
  # ============================================================

  defp sanitize(texto) when is_binary(texto) do
    texto
    |> String.replace(",", ";")
    |> String.replace("\n", " ")
  end

  defp parse_nil(""), do: nil
  defp parse_nil(valor), do: valor

  defp parse_bool("true"), do: true
  defp parse_bool("false"), do: false
  defp parse_bool(_), do: false
end
