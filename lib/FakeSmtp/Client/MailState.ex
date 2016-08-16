require Logger

defmodule FakeSmtp.Client.MailState do
  def empty do
    %{}
  end

  def handle_line(state, line) do
    case Map.get(state, :state) do
      :data -> handle_data_line(state, line)
      nil -> handle_root_line(state, line)
    end
  end

  defp handle_root_line(state, line) do
    case String.split(line) do
      ["HELO" | _args] ->
        {:ok, state, "250 localhost\r\n"}
      ["MAIL", "FROM:", email] ->
        {:ok, Map.put(state, :from, email), "250 Ok\r\n"}
      ["RCPT", "TO:", email] ->
        {:ok, Map.put(state, :to, email), "250 Ok\r\n"}
      ["DATA"] ->
        {:ok, Map.put(state, :state, :data), "354 End data with <CR><LF>.<CR><LF>\r\n"}
      ["QUIT"] ->
        # move this to better place
        {:ok, file} = File.open("hello.eml", [:write])
        IO.binwrite(file, Map.get(state, :data))
        File.close(file)
        {:close, state, "221 Bye\r\n"}
      _ ->
        {:ok, state, :noreply}
    end
  end

  defp handle_data_line(state, line) do
    case line do
      ".\r\n" -> {:ok, Map.delete(state, :state), "250 Ok\r\n"}
      line ->
        current_data = Map.get(state, :data) || ""
        {:ok, Map.put(state, :data, current_data <> line), :noreply}
    end
  end
end
