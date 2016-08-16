defmodule FakeSmtp.Server.Supervisor do
  def start_link do
    import Supervisor.Spec

    children = [
      supervisor(Task.Supervisor, [[name: FakeSmtp.Server.TaskSupervisor]]),
      worker(Task, [FakeSmtp.Server, :accept, [10025]])
    ]

    opts = [strategy: :one_for_one, name: FakeSmtp.Server.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
