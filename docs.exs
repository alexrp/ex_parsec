Mix.Task.run("do", "deps.get", "deps.compile", "docs")
ghp = "gh-pages"
{b, 0} = System.cmd("git", ["rev-parse", "--abbrev-ref", "HEAD"])
{_, 0} = System.cmd("git", ["checkout", ghp])
paths = Path.wildcard("*", [match_dot: true])
Enum.each(paths, fn(p) -> if !(p in [".git", "docs"]), do: File.rm_rf!(p) end)
File.cp_r! "docs/.", "."
File.rm_rf! "docs"
{_, 0} = System.cmd("git", ["add", "."])
{_, 0} = System.cmd("git", ["commit", "--message", "\"Update documentation.\""])
{_, 0} = System.cmd("git", ["push", "origin", ghp])
{_, 0} = System.cmd("git", ["checkout", String.strip(b)])
{_, 0} = System.cmd("git", ["checkout", "."])
{_, 0} = System.cmd("git", ["clean", "-d", "--force", "-x"])
