require 'test_helper'

class ChannelQueuesControllerTest < ActionController::TestCase
  setup do
    ENV['SLACK_SIGNING_SECRET'] = 'ade6ca762ade4db0e7d31484cd616b9c'
    @timestamp = '1531221943'
  end

  def test_index
    Time.zone.stubs(:now).returns(Time.at(@timestamp.to_i) + 3.minutes)

    set_headers

    expected_response_body = { text: 'response body text' }
    ChannelQueues::ResponseRetriever.expects(:retrieve).with('list', 'C123', 'my-channel', 'U123', 'my.user').returns(expected_response_body)

    get :index, { text: 'list', token: '12345', channel_id: 'C123', channel_name: 'my-channel', user_id: 'U123', user_name: 'my.user' }

    assert_response :ok
    body = JSON.parse(response.body).symbolize_keys
    assert_equal expected_response_body, body
  end

  def test_index__invalid_signing_secret
    Time.zone.stubs(:now).returns(Time.at(@timestamp.to_i) + 3.minutes)

    set_headers(signing_secret: 'invalid')

    ChannelQueues::ResponseRetriever.expects(:retrieve).never

    get :index, { text: 'list', token: '12345', channel_id: 'C123', channel_name: 'my-channel', user_id: 'U123', user_name: 'my.user' }

    assert_response :ok
    body = JSON.parse(response.body).symbolize_keys
    assert_equal({ text: 'Slack signature invalid' }, body)
  end

  def test_index__old_timestamp
    Time.zone.stubs(:now).returns(Time.at(@timestamp.to_i) + 6.minutes)

    set_headers

    ChannelQueues::ResponseRetriever.expects(:retrieve).never

    get :index, { text: 'list', token: '12345', channel_id: 'C123', channel_name: 'my-channel', user_id: 'U123', user_name: 'my.user' }

    assert_response :ok
    body = JSON.parse(response.body).symbolize_keys
    assert_equal({ text: 'Slack signature invalid' }, body)
  end

  private

  def set_headers(signing_secret: ENV['SLACK_SIGNING_SECRET'])
    request.headers['X-Slack-Request-Timestamp'] = @timestamp

    basestring = "v0:#{@timestamp}:"
    request.headers['X-Slack-Signature'] = "v0=#{OpenSSL::HMAC.hexdigest("SHA256", signing_secret, basestring)}"
  end
end
