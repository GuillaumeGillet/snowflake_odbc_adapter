require "test_helper"

class TestConnectionManagement < Minitest::Test
  def test_connection_management
    assert conn.active?

    conn.disconnect!
    assert_not conn.active?

    conn.disconnect!
    assert_not conn.active?

    conn.reconnect!
    assert conn.active?
  ensure
    conn.reconnect!
  end

  private

  def conn
    ActiveRecord::Base.connection
  end
end
