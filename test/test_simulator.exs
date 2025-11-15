# scripts/test_simulator.exs

Mix.Task.run("app.start")

alias ProyectoFinalPrg3.Services.{
  TeamService,
  ProjectService,
  MessageService,
  MentorService,
  ProgressService
}

alias ProyectoFinalPrg3.Domain.{Participant}

defmodule TestSimulator do
  @moduledoc """
  Simula la ejecución de una hackathon real:

    • Creación dinámica de participantes y equipos
    • Asignación de proyectos
    • Mensajes en tiempo real en salas de chat
    • Retroalimentación de mentores
    • Avances de proyectos cada cierto tiempo
    • Actividad simultánea entre nodos

  Este script sirve como prueba integral del sistema.
  """

  # ----------------------------------------------------------------------
  # 1. Generar participantes
  # ----------------------------------------------------------------------

  def generate_participants(n) do
    Enum.map(1..n, fn i ->
      %Participant{
        id: "user#{i}",
        nombre: "User #{i}",
        correo: "user#{i}@hackathon.com",
        habilidades: ["backend", "frontend", "IA"]
      }
    end)
  end

  # ----------------------------------------------------------------------
  # 2. Crear equipos y asignar participantes
  # ----------------------------------------------------------------------

  def create_teams(participants) do
    IO.puts("Creando equipos...")

    participants
    |> Enum.chunk_every(5)
    |> Enum.with_index()
    |> Enum.map(fn {members, index} ->
      {:ok, team} = TeamService.create_team("Team_#{index + 1}", "Equipo de prueba", "Tecnología")

      Enum.each(members, fn p ->
        TeamService.add_participant(team.id, p)
      end)

      team
    end)
  end

  # ----------------------------------------------------------------------
  # 3. Crear proyectos y asignarlos a equipos
  # ----------------------------------------------------------------------

  def assign_projects(teams) do
    IO.puts("Asignando proyectos...")

    Enum.map(teams, fn team ->
      {:ok, project} =
        ProjectService.create_project(%{
          nombre: "Proyecto #{team.nombre}",
          descripcion: "Descripción para #{team.nombre}",
          categoria: "Innovación",
          estado: :iniciado
        })

      ProjectService.assign_project_to_team(team.id, project.id)

      {team, project}
    end)
  end

  # ----------------------------------------------------------------------
  # 4. Simular chat activo en tiempo real
  # ----------------------------------------------------------------------

  def simulate_chat(team, msgs) do
    Enum.each(1..msgs, fn i ->
      Task.start(fn ->
        MessageService.send_to_team(team.id, %{
          autor: "bot",
          contenido: "Mensaje #{i} para #{team.nombre}"
        })
      end)
    end)
  end

  # ----------------------------------------------------------------------
  # 5. Simular avances del proyecto
  # ----------------------------------------------------------------------

  def simulate_progress(project) do
    Task.start(fn ->
      for p <- 1..10 do
        ProgressService.register_progress(project.id, %{
          descripcion: "Avance #{p}",
          porcentaje: p * 10,
          timestamp: DateTime.utc_now()
        })

        :timer.sleep(700)
      end
    end)
  end

  # ----------------------------------------------------------------------
  # 6. Simular retroalimentación de mentores
  # ----------------------------------------------------------------------

  def simulate_mentors(projects) do
    IO.puts("Asignando mentores...")

    {:ok, mentor} =
      MentorService.register(%{
        nombre: "Mentor Principal",
        correo: "mentor@test.com",
        especialidad: "Arquitectura"
      })

    Enum.each(projects, fn {_team, project} ->
      Task.start(fn ->
        MentorService.send_feedback(project.id, mentor.id, "Revisión completa del proyecto.")
      end)
    end)
  end

  # ----------------------------------------------------------------------
  # Ejecución principal
  # ----------------------------------------------------------------------

  def run do
    IO.puts("=== INICIANDO SIMULACIÓN COMPLETA ===")

    participants = generate_participants(40)
    teams = create_teams(participants)
    team_project_map = assign_projects(teams)

    Enum.each(team_project_map, fn {team, project} ->
      simulate_chat(team, 80)
      simulate_progress(project)
    end)

    simulate_mentors(team_project_map)

    IO.puts("=== SIMULACIÓN EJECUTADA CORRECTAMENTE ===")
  end
end

TestSimulator.run()
