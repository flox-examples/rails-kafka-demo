class PostsController < ApplicationController
  def index
    posts = Post.order(created_at: :desc).limit(50)
    render json: posts
  end

  def show
    post = Post.find(params[:id])
    render json: post_with_audit(post)
  end

  def create
    post = Post.create!(post_params)
    render json: post, status: :created
  end

  private

  def post_params
    params.require(:post).permit(:title, :body)
  end

  def post_with_audit(post)
    audit_url = "#{kafka_config['audit_service_url']}/audit_logs?post_id=#{post.id}"
    audit_response = Net::HTTP.get_response(URI(audit_url))
    audit_data = JSON.parse(audit_response.body) if audit_response.is_a?(Net::HTTPSuccess)

    post.as_json.merge(audit_logs: audit_data || [])
  rescue => e
    Rails.logger.warn "[AuditService] Could not fetch audit logs: #{e.message}"
    post.as_json.merge(audit_logs: [])
  end

  def kafka_config
    @kafka_config ||= Rails.application.config_for(:kafka)
  end
end
