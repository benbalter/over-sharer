require 'sinatra/base'
require 'octokit'
require 'redis'
require 'json'
require 'sinatra/auth/github'
require 'dotenv'
require 'tilt/erb'

Dotenv.load

class OverSharer < Sinatra::Base

  configure :production do
    require 'rack-ssl-enforcer'
    use Rack::SslEnforcer
  end

  set :method_override, true

  configure do
    @@redis = Redis.new(url: ENV["REDIS_URL"])
  end

  use Rack::Session::Cookie, {
    :http_only => true,
    :secret    => ENV['SESSION_SECRET'] || SecureRandom.hex
  }

  set :github_options, { :scopes => 'repo,repo_private' }
  ENV['WARDEN_GITHUB_VERIFIER_SECRET'] ||= SecureRandom.hex
  register Sinatra::Auth::Github

  def redis
    self.class.class_variable_get(:@@redis)
  end

  def get_doc(id)
    data = redis.get(id)
    JSON.parse(data) if data
  end

  def set_doc(id, doc)
    redis.set id, doc.to_json
  end

  def pullable?(repo)
    client = Octokit::Client.new access_token: github_user.token
    !!client.repository(repo)
  rescue
    false
  end

  get "/" do
    erb :index, locals: { msg: "" }
  end

  post "/" do
    # parse the GitHub URL
    begin
      url = URI.parse params[:github_url]
      match, repo, ref, path = url.path.match(/\A\/([^\/]+\/[^\/]+)\/blob\/([^\/]+)\/(.*)\z/).to_a
    rescue URI::InvalidURIError
      halt erb :index, locals: { msg: "Invalid URL" }
    end

    # Confirm user can pull from the repo
    authenticate!
    halt 406 unless pullable?(repo)

    # Store the doc and token
    id = SecureRandom.uuid
    set_doc id, {
      repo:  repo,
      ref:   ref,
      path:  path,
      token: github_user.token
    }

    redirect "/#{id}"
  end

  get "/:id" do
    doc = get_doc params[:id]
    halt 404 unless doc

    client   = Octokit::Client.new access_token: doc["token"]
    response = client.contents doc["repo"], path: doc["path"], ref: doc["ref"]
    markdown = Base64.decode64(response.content).force_encoding("UTF-8")
    html     = client.markdown markdown, mode: "gfm", context: doc["repo"]

    erb :show, locals: {
      repo: doc["repo"],
      ref:  doc["ref"],
      path: doc["path"],
      url:  response.html_url,
      contents: html,
      created_by: client.user
    }
  end

  delete "/:id" do
    redis.del params[:id]
    erb :index, locals: { msg: "Document unshared" }
  end
end
