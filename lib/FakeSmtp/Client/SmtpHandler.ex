require Logger

defmodule FakeSmtp.Client.SmtpHandler do
  def init(socket) do
    mail_state = FakeSmtp.Client.MailState.empty
    write_line(socket, {:ok, "220 localhost ESMTP server ready\r\n"})
    serve(socket, mail_state)
  end

  def serve(socket, mail_state) do
    {next_state, msg} = case read_line(socket) do
      {:ok, line} ->
        case FakeSmtp.Client.MailState.handle_line(mail_state, line) do
          {:ok, new_state, :noreply} -> {new_state, {:noreply}}
          {:ok, new_state, msg} -> {new_state, {:ok, msg}}
          {:close, new_state, msg} -> {new_state, {:write_close, msg}}
        end
      {:error, _} = err -> {mail_state, err}
    end

    write_line(socket, msg)
    serve(socket, next_state)
  end

  defp read_line(socket) do
    :gen_tcp.recv(socket, 0)
  end

  defp write_line(socket, {:ok, text}) do
    :gen_tcp.send(socket, text)
  end

  defp write_line(_socket, {:noreply}) do
  end

  defp write_line(socket, {:write_close, text}) do
    write_line(socket, {:ok, text})
    exit(:shutdown)
  end

  defp write_line(_socket, {:error, :closed}) do
    Logger.info("Connection to remote client closed")
    exit(:shutdown)
  end
end
