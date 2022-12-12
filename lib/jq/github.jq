def trim:
  gsub("^\\s+|\\s+$"; "")
  ;

# Expects a repository_url (e.g. https://api.github.com/repos/cgrindel/swift_toolbox)
def repo_title:
  split("/") | .[-2:] | join("/") as $suffix |
  {
    "aspect-build/aspect-cli": "Aspect CLI",
    "aspect-build/bazel-lib": "Aspect Bazel Lib",
    "bazel-contrib/rules_bazel_integration_test": "Bazel Integration Test Rules",
    "bazelbuild/bazel-gazelle": "Bazel Gazelle",
    "bazelbuild/rules_pkg": "Bazel Packaging Rules",
    "buildbuddy-io/rules_xcodeproj": "Xcode Project Generator",
    "cgrindel/bazel-starlib": "Bazel Starlib",
    "cgrindel/dev-machine": "Dev Machine",
    "cgrindel/fly-without-fear": "Fly Without Fear",
    "cgrindel/github_snippets": "GitHub Snippets",
    "cgrindel/rules_spm": "Swift Package Manager Rules for Bazel",
    "cgrindel/rules_swiftformat": "SwiftFormat Rules for Bazel",
    "cgrindel/spm_bazel": "SPM Bazel",
    "cgrindel/swift_bazel": "Swift Bazel",
    "cgrindel/swift_toolbox": "Swift Toolbox"
  } as $repo_titles |
  [ ($repo_titles | getpath([$suffix])), "`\($suffix)`" ] |
  map(select(.)) | 
  join(" ")
  ;

# Closed PRs

def format_pr_body: 
  . // "" |
  # Split the array by line
  [ . | split("\n")[] | 
    trim | 
    # Filter out empty lines
    select(. != "") |
    # Filter out magical phrases that link to issues
    select(test("\\bClose[sd]?\\s+[#][0-9]+"; "ix") | not) |
    select(test("\\bResolve[sd]?\\s+[#][0-9]+"; "ix") | not) |
    select(test("\\bRelated\\s+to\\s+[#][0-9]+"; "ix") | not) | 
    # Indent the lines
    "  " + .
  ] |
  # Join the lines into a single string.
  join("\n") |
  if . == "" then null else . end
  ;


def closed_pr_to_md:
  ["- [\(.title)](\(.html_url))", (.body | format_pr_body) ] | 
  map(select(.)) |
  join("\n") 
  ;

# Expects an array of PRs that are already grouped by repository_url
def closed_repo_prs_to_md:
  "## \(.[0].repository_url | repo_title)" as $repo_url |
  map(. | closed_pr_to_md) as $pr_mds |
  [ $repo_url ] + $pr_mds |
  join("\n")
  ;


def closed_pr_search_response_to_md:
  [ .items | group_by(.repository_url) | .[] | closed_repo_prs_to_md ] |
  join("\n\n")
  ;

# Reviewed PRs

def reviewed_pr_to_md:
  ["  - [\(.title)](\(.html_url))"] | 
  map(select(.)) |
  join("\n") 
  ;

def reviewed_repo_prs_to_md:
  "- \(.[0].repository_url | repo_title)" as $repo_url |
  map(. | reviewed_pr_to_md) as $pr_mds |
  [ $repo_url ] + $pr_mds |
  join("\n")
  ;

def reviewed_pr_search_response_to_md:
  [ .items | group_by(.repository_url) | .[] | reviewed_repo_prs_to_md ] |
  [ "## Reviewed PRs" ] + . |
  join("\n")
  ;
