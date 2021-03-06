require 'git'

# Helper For Working With Git Repositories
module Git
  def self.repository?(path)
    Dir.exist?(path) && Dir.children(path).include?('.git')
  end

  def self.clone?(repository, target_path)
    Git.clone(
      repository,
      path: target_path,
      options: { depth: 1 }
    )
  end
end
