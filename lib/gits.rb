require 'tmpdir'
require 'cli/ui'

require_relative './gits/parser'
require_relative './gits/search'

require_relative './helpers/git'

# Gits Module
module Gits
  def self.initialize
    @repositories = []
    @search_client = Gits::Search.new
    @gits_dir = File.join(Dir.tmpdir, 'gits')

    working_dir = Dir.pwd
    @repositories.push(working_dir) if Git.repository?(working_dir)
  end

  def self.cloned_repositories
    cloned_repositories =
      Dir.glob('**', base: @gits_dir)
        .map do |user_dir|
        Dir.glob('**', base: File.join(@gits_dir, user_dir))
          .map { |repo_dir| File.join(@gits_dir, user_dir, repo_dir) }
      end.flatten

    @repositories.concat cloned_repositories
  end

  def self.repository_prompt
    @selected_repository =
      CLI::UI.ask(
        'What Git repository do you want to search?',
        default: @repositories.first,
        is_file: true
      )
  end

  def self.handle_selected_repository
    return if @selected_repository == @repositories.first || Git.repository?(@selected_repository)

    selected_new_repository? if selected_previously_cloned_repository? == false
  end

  def self.search_query_prompt
    @search_query =
      CLI::UI.ask('Search query:')
  end

  def self.search_results
    @search_client.search(@selected_repository, @search_query)
  end

  def self.selected_previously_cloned_repository?
    repository_index = Integer(@selected_repository, exception: false)
    if repository_index.nil?
      false
    else
      # Check If Selection Is Out-Of-Bounds
      unless @repositories[repository_index]
        puts "#{repository_index} Is An Invalid Selection"
        exit
      end

      @selected_repository = @repositories[repository_index]

      true
    end
  end

  def self.selected_new_repository?
    git_remote = Gits::Parser.new.parse(@selected_repository)
    if git_remote.nil?
      puts "The Selected Repository (#{@selected_repository}) Is Not Valid"
      exit
    else
      # /tmp/gits/git_repo_owner/git_repo_name
      repo_dir = File.join(@gits_dir, git_remote.owner, git_remote.repo)

      unless Dir.exist?(repo_dir)
        FileUtils.mkdir_p(repo_dir) # Recursively Create Directories
        puts "Downloading: #{git_remote.html_url} -> #{repo_dir}"
        Git.clone(git_remote.html_url, repo_dir)
      end

      @selected_repository = repo_dir
      true
    end
  end
end
