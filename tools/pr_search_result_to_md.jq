def trim:
  gsub("^\\s+|\\s+$"; "")
  ;


def format_pr_body: 
  [ . | split("\n")[] | trim | select(. != "") ] |
  join("\n")
  ;

def pr_to_md:
  "- [\(.title)](\(.html_url))" as $title_line | 
  if .body then "\($title_line)\n\(.body | format_pr_body)" else $title_line end
  ;

# Output each PR as markdown
.items[] | pr_to_md
