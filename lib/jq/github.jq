def trim:
  gsub("^\\s+|\\s+$"; "")
  ;


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


def pr_to_md:
  ["- [\(.title)](\(.html_url))", (.body | format_pr_body) ] | 
  map(select(.)) |
  join("\n") 
  ;

# Expects an array of PRs that are already grouped by repository_url
def repo_prs_to_md:
  "## \(.[0].repository_url)" as $repo_url |
  map(. | pr_to_md) as $pr_mds |
  [ $repo_url ] + $pr_mds |
  join("\n")
  ;


def pr_search_response_to_md:
  # .items | group_by(.repository_url) | .[] | repo_prs_to_md
  [ .items | group_by(.repository_url) | .[] | repo_prs_to_md ] |
  join("\n\n")
  ;
