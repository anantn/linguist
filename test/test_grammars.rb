require_relative "./helper"

class TestGrammars < Test::Unit::TestCase
  ROOT = File.expand_path("../..", __FILE__)

  def setup
    @grammars = YAML.load(File.read(File.join(ROOT, "grammars.yml")))
  end

  def test_no_duplicate_scopes
    scopes = @grammars.values.flatten
    duplicates = scopes.group_by { |s| s }.select { |k, v| v.length > 1 }.map(&:first)
    assert duplicates.empty?, "The following scopes appear in grammars.yml more than once:\n#{duplicates.sort.join("\n")}"
  end

  def test_submodules_are_in_sync
    submodules = `git config --list --file "#{File.join(ROOT, ".gitmodules")}"`.lines.grep(/\.path=/).map { |line| line.chomp.split("=", 2).last }
    # Strip off paths inside the submodule so that just the submodule path remains.
    listed_submodules = @grammars.keys.grep(/grammar_sources/).map { |source| source[%r{grammar_sources/[^/]+}] }

    nonexistent_submodules = listed_submodules - submodules
    unlisted_submodules = submodules - listed_submodules

    message = ""
    unless nonexistent_submodules.empty?
      message << "The following submodules are listed in grammars.yml but don't seem to exist in the repository. Maybe you should remove them from grammars.yml?\n"
      message << nonexistent_submodules.sort.join("\n")
    end
    unless unlisted_submodules.empty?
      message << "\n" unless message.empty?
      message << "The following submodules exist in the repository but aren't listed in grammars.yml. Maybe you should add them to grammars.yml?\n"
      message << unlisted_submodules.sort.join("\n")
    end

    assert nonexistent_submodules.empty? && unlisted_submodules.empty?, message
  end
end
