require "test_helper"

class TestVersion < Minitest::Test
  def test_version
    assert_not_nil SnowflakeOdbcAdapter::VERSION
  end
end
