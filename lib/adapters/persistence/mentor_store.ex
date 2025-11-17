defmodule ProyectoFinalPrg3.Adapters.Persistence.MentorStore do
  @moduledoc """
  Persistencia de mentores alineada al dominio Mentor.

  Guarda únicamente los campos definidos en el dominio:
  id, nombre, correo, contrasena, especialidad.
  Proporciona operaciones CRUD y consultas específicas.
  Autores: [Sharif Giraldo Obando, Juan Sebastián Hernández y Santiago Ospina Sánchez]
  Fecha de creación: 2025-11-16
  Fecha de última modificación: 2025-11-16
  Licencia: GNU GPL v3
  """

  alias ProyectoFinalPrg3.Domain.Mentor

  @ruta Path.join([File.cwd!(), "data", "mentores.csv"])
  @headers "id,nombre,correo,contrasena,especialidad\n"

  # ============================================================
  # CRUD PRINCIPAL
  # ============================================================

  @doc """
  Guarda o actualiza un mentor basado en su id.
  Parámetros:
    - `mentor`: Struct %Mentor{} a guardar o actualizar.
  Retorna:
    - `{:ok, mentor}` confirmando la operación.
  """
  def guardar_mentor(%Mentor{} = mentor) do
    lista =
      listar_mentores()
      |> Enum.reject(&(&1.id == mentor.id))
      |> Kernel.++([mentor])

    escribir_mentores(lista)
    {:ok, mentor}
  end

  @doc """
  Obtiene un mentor por su ID.
  Parámetros:
    - `id`: Identificador único del mentor.
  Retorna:
    - Mentor encontrado o nil si no existe.
  """
  def obtener_por_id(id) do
    listar_mentores()
    |> Enum.find(&(&1.id == id))
  end

  @doc """
  Obtiene un mentor por correo.
  Parámetros:
    - `correo`: Correo electrónico del mentor.
  Retorna:
    - Mentor encontrado o nil si no existe.
  """
  def buscar_por_correo(correo) do
    listar_mentores()
    |> Enum.find(&(&1.correo == correo))
  end

  @doc """
  Lista todos los mentores almacenados.
  Parámetros: Ninguno.
  Retorna:
    - Lista de mentores.
  """
  def listar_mentores do
    if File.exists?(@ruta) do
      File.stream!(@ruta)
      |> Stream.drop(1)
      |> Stream.map(&parse_line/1)
      |> Enum.to_list()
    else
      []
    end
  rescue
    _ -> []
  end

  @doc """
  Elimina un mentor por ID.
  Parámetros:
    - `id`: Identificador único del mentor.
  Retorna:
    - `:ok`.
  """
  def eliminar_mentor(id) do
    nuevos =
      listar_mentores()
      |> Enum.reject(&(&1.id == id))

    escribir_mentores(nuevos)
    :ok
  end

  # ============================================================
  # SERIALIZACIÓN
  # ============================================================

  @doc false
  defp parse_line(line) do
    [id, nombre, correo, contrasena, especialidad] =
      line
      |> String.trim()
      |> String.split(",", parts: 5)

    %Mentor{
      id: id,
      nombre: nombre,
      correo: correo,
      contrasena: contrasena,
      especialidad: if(especialidad == "", do: nil, else: especialidad)
    }
  end

  @doc false
  defp escribir_mentores(lista) do
    contenido =
      lista
      |> Enum.map(&to_csv/1)
      |> Enum.join("\n")

    File.mkdir_p!("data")
    File.write!(@ruta, @headers <> contenido <> "\n")
  end

  @doc false
  defp to_csv(%Mentor{
         id: id,
         nombre: nombre,
         correo: correo,
         contrasena: contrasena,
         especialidad: especialidad
       }) do
    [
      id,
      sanitize(nombre),
      correo,
      contrasena,
      sanitize(especialidad)
    ]
    |> Enum.join(",")
  end

  # ============================================================
  # UTILIDADES
  # ============================================================

  @doc false
  defp sanitize(texto) when is_binary(texto) do
    texto
    |> String.replace(",", ";")
    |> String.replace("\n", " ")
  end

  @doc false
  defp sanitize(_), do: ""
end
