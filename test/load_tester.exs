# scripts/load_tester.exs

Mix.Task.run("app.start")

alias ProyectoFinalPrg3.Services.{
  TeamService,
  ProjectService,
  MessageService,
  ProgressService,
  MentorService
}

alias ProyectoFinalPrg3.Domain.{Participant, Team, Project, Message, Progress}

defmodule LoadTester do
  @moduledoc """
  Script de pruebas de carga y estrés para el sistema distribuido de Hackathon.

  Mide:
    • Rendimiento del sistema bajo alta concurrencia
    • Latencia promedio por operación
    • Capacidad de creación masiva de entidades
    • Tolerancia a fallos en operaciones simultáneas
  """

  # ----------------------------------------------------------------------
  # Utilidades de tiempo
  # ----------------------------------------------------------------------

  defp now_ms, do: System.monotonic_time(:millisecond)

  defp measure(desc, fun) do
    start = now_ms()
    result = fun.()
    finish = now_ms()
    time = finish - start

    IO.puts("[#{desc}] → #{time} ms")
    {result, time}
  end

  # ----------------------------------------------------------------------
  # Prueba 1: Creación masiva de participantes
  # ----------------------------------------------------------------------

  def mass_create_participants(n) do
    measure("Creación de #{n} participantes", fn ->
      1..n
      |> Enum.map(fn i ->
        %Participant{
          id: "p#{i}",
          nombre: "Usuario #{i}",
          correo: "usuario#{i}@test.com",
          habilidades: ["backend", "frontend", "IA"] |> Enum.take_random(1)
        }
      end)
    end)
  end

  # ----------------------------------------------------------------------
  # Prueba 2: Creación masiva de equipos
  # ----------------------------------------------------------------------

  def mass_create_teams(n) do
    measure("Creación de #{n} equipos", fn ->
      Enum.map(1..n, fn i ->
        TeamService.create_team("Equipo #{i}", "Descripción #{i}", "Tecnología")
      end)
    end)
  end

  # ----------------------------------------------------------------------
  # Prueba 3: Generación de proyectos
  # ----------------------------------------------------------------------

  def mass_create_projects(n) do
    measure("Creación de #{n} proyectos", fn ->
      Enum.map(1..n, fn i ->
        ProjectService.create_project(%{
          nombre: "Proyecto #{i}",
          descripcion: "Descripción del proyecto #{i}",
          categoria: "Innovación",
          estado: :iniciado
        })
      end)
    end)
  end

  # ----------------------------------------------------------------------
  # Prueba 4: Envío de mensajes concurrentes
  # ----------------------------------------------------------------------

  def mass_messages(team_id, msg_count) do
    measure("Envío de #{msg_count} mensajes concurrentes", fn ->
      tasks =
        for i <- 1..msg_count do
          Task.async(fn ->
            MessageService.send_to_team(team_id, %{
              autor: "tester#{i}",
              contenido: "Mensaje de prueba #{i}"
            })
          end)
        end

      Task.await_many(tasks, 5000)
    end)
  end

  # ----------------------------------------------------------------------
  # Prueba 5: Simulación de avances concurrentes
  # ----------------------------------------------------------------------

  def mass_progress(project_id, n) do
    measure("Registro de #{n} avances concurrentes", fn ->
      tasks =
        for i <- 1..n do
          Task.async(fn ->
            ProgressService.register_progress(project_id, %{
              descripcion: "Avance #{i}",
              timestamp: DateTime.utc_now(),
              porcentaje: rem(i * 5, 100)
            })
          end)
        end

      Task.await_many(tasks)
    end)
  end

  # ----------------------------------------------------------------------
  # Ejecución principal
  # ----------------------------------------------------------------------

  def run do
    IO.puts("===== INICIO PRUEBAS DE CARGA =====")

    {_, _} = mass_create_participants(300)
    {teams, _} = mass_create_teams(50)
    {projects, _} = mass_create_projects(30)

    team = List.first(teams)
    project = List.first(projects)

    mass_messages(team.id, 700)
    mass_progress(project.id, 300)

    IO.puts("===== FIN DE PRUEBAS DE CARGA =====")
  end
end

LoadTester.run()
