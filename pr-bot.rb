require 'json'
require 'fileutils'

# include gems defined in Gemfile
require 'bundler/setup'
Bundler.require(:default)

# useful, for when have to cut down the file content passed in
# OpenAI.rough_token_count("Your text")

class ChatGPTIntegration
  def initialize
    @client = OpenAI::Client.new(access_token: ENV["OPENAI_API_KEY"])
  end

  def fetch_directory_tree(path = '.')
    Dir.glob("#{path}/**/*", File::FNM_DOTMATCH).reject { |e| File.directory?(e) }
  end

  def ask_gpt(prompt)
    response = client.chat(
      parameters: {
        model: "gpt-4",
        messages: [{ role: "user", content: prompt }],
        temperature: 0.1,
      }
    )
    response.dig("choices", 0, "message", "content")
  end

  # ... other methods
end
