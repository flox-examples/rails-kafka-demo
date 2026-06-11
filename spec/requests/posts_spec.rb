require "rails_helper"

RSpec.describe "Posts", type: :request do
  describe "GET /posts" do
    it "returns an empty list" do
      get "/posts"
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to eq([])
    end

    it "returns existing posts ordered newest first" do
      older = create(:post, title: "Older", created_at: 2.minutes.ago)
      newer = create(:post, title: "Newer", created_at: 1.minute.ago)
      get "/posts"
      ids = JSON.parse(response.body).map { |p| p["id"] }
      expect(ids).to eq([ newer.id, older.id ])
    end
  end

  describe "POST /posts" do
    context "with valid params" do
      it "creates a post and returns 201" do
        post "/posts", params: { post: { title: "Hello", body: "World" } }
        expect(response).to have_http_status(:created)
        body = JSON.parse(response.body)
        expect(body["title"]).to eq("Hello")
        expect(body["status"]).to eq("pending")
      end

      it "publishes a Kafka event" do
        post "/posts", params: { post: { title: "Kafka test", body: "payload" } }
        expect(Kafka::Producer).to have_received(:publish).with(
          topic: "posts.created",
          payload: anything,
          key: anything
        )
      end
    end

    context "with invalid params" do
      it "returns 422 when title is missing" do
        post "/posts", params: { post: { body: "No title" } }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)["errors"]).to include("Title can't be blank")
      end
    end
  end

  describe "GET /posts/:id" do
    it "returns the post with audit_logs field" do
      p = create(:post)
      stub_request(:get, /localhost:3001\/audit_logs/)
        .to_return(status: 200, body: [ { "id" => 1, "post_id" => p.id } ].to_json)

      get "/posts/#{p.id}"
      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["id"]).to eq(p.id)
      expect(body).to have_key("audit_logs")
    end

    it "returns empty audit_logs when audit service is down" do
      p = create(:post)
      stub_request(:get, /localhost:3001\/audit_logs/).to_timeout

      get "/posts/#{p.id}"
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)["audit_logs"]).to eq([])
    end

    it "returns 404 for a missing post" do
      get "/posts/99999"
      expect(response).to have_http_status(:not_found)
    end
  end
end
