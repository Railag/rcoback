require 'test_helper'

class GroupControllerTest < ActionDispatch::IntegrationTest
  test "should get create" do
    get group_create_url
    assert_response :success
  end

end
