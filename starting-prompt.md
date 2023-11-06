Write some Ruby code for a PR Bot, confomring to the following specification
- Is a class which takes an OpenAI API key in it's main initializer
  - Able to see the directory tree from the current application
- Has methods for file management
  - add_file(filepath, contents)
  - change_file(filepath, original, new)

- Has a method called `convert_feature_request_to_instructions` which can perform the following steps in service of converting a feature request into an implementation attempt of that feature
  1. Send to ChatGPT: Provide feature request and the current directory tree, and ask for a list of files it would need to see in order for it to know how to implement the feature
  2. Pass a new request to the API with the feature request and the contents of the requested supporting files, ask how it would implement the feature request using add_file(filepath, contents) and change_file(filepath, original, new) methods

- Has a method called `run_chatgpt_instructions` which can take the output of the last request and can call the methods instructed by ChatGPT in order to change the local files

- Has a method called `save_git_commit` which
  - asks chatGPT for a good branch name and commit message, provide the git diff and the feature request
  - checks out a new branch based on the branch name provided
  - run git add, and git commit with the commit message provided

here's your starting point:
