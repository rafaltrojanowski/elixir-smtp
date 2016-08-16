defmodule FakeSmtp do
  use Application


  def start(_type, _args) do
    FakeSmtp.Server.Supervisor.start_link()
  end
end
