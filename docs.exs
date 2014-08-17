Mix.Task.run("docs")
{b, 0} = System.cmd("git", ["rev-parse", "--abbrev-ref", "HEAD"])
{_, 0} = System.cmd("git", ["checkout", "gh-pages"])
paths = Path.wildcard("*", [match_dot: true])
Enum.each(paths, fn(p) -> if !(p in [".git", "docs"]), do: File.rm_rf!(p) end)
File.cp_r! "docs/.", "."
File.rm_rf! "docs"
{_, 0} = System.cmd("git", ["checkout", String.strip(b)])
