require 'json'
require 'fileutils'
load 'file_helpers.rb'

# include gems defined in Gemfile
require 'bundler/setup'
Bundler.require(:default)

PROJECT_CONTEXT = [
  # "it uses tailwindCSS",
  # "do not define custom styles"
]

class PRBot
  include FileHelpers
  def initialize(feature_request)
    @feature_request = feature_request
  end

  def ask_for_contextual_files
    directory_tree = fetch_directory_tree
    files_needed_prompt = [
      "What files from the Directory Tree should I review to implement the following feature request in this project?",
      "Directory Tree:",
      "#{directory_tree.join("\n")}",
      "Feature request: #{@feature_request}",
      "Respond with minimal prose",
      "Things to know about this project: [#{PROJECT_CONTEXT.join(', ')}]"
    ].join("\n")
    files_needed = ask_gpt(files_needed_prompt)

    # Extracting the list of files from the GPT response
    files_needed.scan(/[\w\-.\/]+/).select { |f| File.file?(f) }
  end

  def convert_feature_request_to_instructions
    files_list = ask_for_contextual_files

    # Preparing content of files
    files_content = files_list.map { |file| { name: file, content: File.read(file) } }

    implement_feature_prompt = [
      "How would you implement the following feature request using Ruby methods add_file(filepath, text) and change_file(filepath, og_text, new_text)?",
      "Feature request: #{@feature_request}",
      "Only make changes to these files, or add new ones if necessary:",
      "#{files_content.to_json}",
      "For each change, provide a short summary and then a ruby code block w/ a single add_file or change_file call (```ruby)",
      "Things to know about this project: [#{PROJECT_CONTEXT.join(', ')}]"
    ].join("\n")

    instructions = ask_gpt(implement_feature_prompt)

    instructions
  end

  def run_chatgpt_instructions(instructions)
    # TODO: Implement this to not split on newlines, but recognize whole blocks of instructions
    # instructions.split("\n").each do |instruction|
    #   if instruction.start_with?("add_file")
    #     _, filepath, text = instruction.match(/add_file\("(.+?)", "(.+?)"\)/).captures
    #     add_file(filepath, JSON.parse(text.gsub('\"', '"')))
    #   elsif instruction.start_with?("change_file")
    #     _, filepath, og_text, new_text = instruction.match(/change_file\("(.+?)", "(.+?)", "(.+?)"\)/).captures
    #     change_file(filepath, JSON.parse(og_text.gsub('\"', '"')), JSON.parse(new_text.gsub('\"', '"')))
    #   end
    # end
  end

  def save_git_commit(feature_request)
    diff = `git diff`
    commit_prompt = "Please provide a good branch name and commit message for the following changes and feature request in the format 'Branch name: [branch_name], Commit message: [commit_message]'.\nGit diff:\n#{diff}\nFeature request: #{feature_request}"
    branch_and_message = ask_gpt(commit_prompt)

    branch_name_match = branch_and_message.match(/Branch name: ([\w\-]+)/)
    commit_message_match = branch_and_message.match(/Commit message: (.+)/)

    branch_name = branch_name_match[1] if branch_name_match
    commit_message = commit_message_match[1] if commit_message_match

    if branch_name && commit_message
      `git checkout -b #{branch_name}`
      `git add .`
      `git commit -m "#{commit_message}"`
    else
      puts "Could not parse branch name and commit message from the following response:\n\n#{branch_and_message}"
    end
  end

  # private

  def ask_gpt(prompt)
    # first check prompt length is less than 2048
    token_count = OpenAI.rough_token_count(prompt)
    if token_count > 2048
      puts "Prompt length is #{token_count} tokens, which is greater than the maximum of 2048 tokens. Please shorten your prompt."
      puts "Prompt start: #{prompt[0..100]}..."
      return
    end

    puts "=========================="
    puts "Requesting: #{prompt[0..100]}...]}"
    puts

    response = client.chat(
      parameters: {
        model: "gpt-4",
        messages: [{ role: "user", content: prompt }],
        temperature: 0.1,
      }
    )

    puts response
    puts

    response.dig("choices", 0, "message", "content")
  end

  def client
    @client ||= OpenAI::Client.new(access_token: ENV["OPENAI_API_KEY"])
  end
end
