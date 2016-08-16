defmodule FakeSmtp.Client.MailStateTest do
  use ExUnit.Case

  test "empty state" do
    assert FakeSmtp.Client.MailState.empty == %{}
  end

  test "handles HELO" do
    state = FakeSmtp.Client.MailState.empty
    assert {:ok, state2, "250 localhost\r\n"} = FakeSmtp.Client.MailState.handle_line(state, "HELO client.example.com\r\n")
    assert state == state2
  end

  test "handles MAIL FROM:" do
    state = FakeSmtp.Client.MailState.empty
    assert {:ok, %{from: "<test@test.com>"}, "250 Ok\r\n"} =
            FakeSmtp.Client.MailState.handle_line(state, "MAIL FROM: <test@test.com>\r\n")
  end

  test "handles RCPT TO:" do
    state = FakeSmtp.Client.MailState.empty
    assert {:ok, %{to: "<test@test.com>"}, "250 Ok\r\n"} =
            FakeSmtp.Client.MailState.handle_line(state, "RCPT TO: <test@test.com>\r\n")
  end

  test "handles DATA" do
    state = FakeSmtp.Client.MailState.empty

    assert {:ok, state2, "354 End data with <CR><LF>.<CR><LF>\r\n"} = FakeSmtp.Client.MailState.handle_line(state, "DATA\r\n")
    assert state2 == %{state: :data}

    assert {:ok, state3, :noreply} = FakeSmtp.Client.MailState.handle_line(state2, "QUIT\r\n")
    assert state3 == %{state: :data, data: "QUIT\r\n"}

    assert {:ok, state4, :noreply} = FakeSmtp.Client.MailState.handle_line(state3, "Another Line ====\r\n")
    assert state4 == %{state: :data, data: "QUIT\r\nAnother Line ====\r\n"}

    assert {:ok, state5, "250 Ok\r\n"} = FakeSmtp.Client.MailState.handle_line(state4, ".\r\n")
    assert state5 == %{data: "QUIT\r\nAnother Line ====\r\n"}
  end

  test "handles QUIT" do
    state = FakeSmtp.Client.MailState.empty
    assert {:close, %{}, "221 Bye\r\n"} = FakeSmtp.Client.MailState.handle_line(state, "QUIT\r\n")
  end

  test "handles empty" do
    state = FakeSmtp.Client.MailState.empty
    assert {:ok, %{}, :noreply} = FakeSmtp.Client.MailState.handle_line(state, "\r\n")
  end
end
