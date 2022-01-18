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
