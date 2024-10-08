require "test_helper"

class TestCalculations < Minitest::Test
  def test_count
    assert_equal 6, User.count
    assert_equal 10, Todo.count
    assert_equal 3, User.find(1).todos.count
  end

  def test_average
    assert_equal 10.33, User.average(:letters).round(2)
  end
end
