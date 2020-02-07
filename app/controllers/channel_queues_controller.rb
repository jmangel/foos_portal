class ChannelQueuesController < ApplicationController
  skip_before_action :verify_authenticity_token

  def index
    return render json: { text: 'Slack signature invalid' } unless request_verified?

    response = ChannelQueues::ResponseRetriever.retrieve(params[:text], params[:channel_id], params[:channel_name], params[:user_id], params[:user_name])
    render json: response
  end

  private

  def request_verified?
    timestamp = request.headers['X-Slack-Request-Timestamp']

    if Time.at(timestamp.to_i) < 5.minutes.ago
      return false # expired
    end

    basestring = "v0:#{timestamp}:#{request.body.read}"
    expected_signature = "v0=#{OpenSSL::HMAC.hexdigest("SHA256", ENV.fetch('SLACK_SIGNING_SECRET'), basestring)}"

    expected_signature == request.headers['X-Slack-Signature']
  end
end
