require "test_helper"

class TestAttributes < Minitest::Test
  def test_booleans?
    assert_equal true, Todo.first.published?
    assert_equal false, Todo.last.published?
  end

  def test_integers
    assert_kind_of Integer, User.first.letters
  end

  def test_strings
    assert_kind_of String, User.first.first_name
    assert_kind_of String, Todo.first.body
  end

  def test_attributes
    assert_kind_of Hash, User.first.attributes
    assert_kind_of Hash, Todo.first.attributes
  end

  def test_json
    assert_kind_of Hash, Document.first.data
    assert_equal({ "key" => { "inner_key" => "value" } }, Document.first.data)
  end
end
