module FileHelpers
  def fetch_directory_tree(path = '.')
    gitignore_path = File.join(path, '.gitignore')
    ignore_patterns = ["./public/*", "./playground/*", "./db/migrate/*"]

    # Read the .gitignore file and build ignore patterns, if it exists
    if File.exist?(gitignore_path)
      File.foreach(gitignore_path) do |line|
        stripped = line.strip
        # Skip comments and empty lines
        next if stripped.start_with?('#') || stripped.empty?
        # Convert the gitignore pattern to a glob pattern
        glob_pattern = stripped.gsub(%r{^/}, '') # Remove leading slash

        # Add glob pattern for root, subdirectory, and recursive subdirectory
        ignore_patterns << File.join(path, glob_pattern)
        ignore_patterns << File.join(path, glob_pattern, "*")
        ignore_patterns << File.join(path, "**", glob_pattern)
        ignore_patterns << File.join(path, "**", glob_pattern, "*")
      end
    end

    # Find all files and reject directories and files matching ignore patterns
    Dir.glob("#{path}/**/*").reject do |e|
      File.directory?(e) || ignore_patterns.any? { |pattern| File.fnmatch(pattern, e) }
    end
  end

  def add_file(filepath, text)
    FileUtils.mkdir_p(File.dirname(filepath))
    File.write(filepath, text)
  end

  def change_file(filepath, og_text, new_text)
    text = File.read(filepath)
    new_file_content = text.gsub(og_text, new_text)
    File.open(filepath, "w") { |file| file.puts new_file_content }
  end
end
