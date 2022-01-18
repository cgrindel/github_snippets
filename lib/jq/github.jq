def trim:
  gsub("^\\s+|\\s+$"; "")
  ;


# def format_pr_body: 
#   # Split the array by line
#   [ . | split("\n")[] | 
#     trim | 
#     # Filter out empty lines
#     select(. != "") |
#     # Filter out magical phrases that link to issues
#     select(test("\\bClose[sd]?\\s+[#][0-9]+"; "ix") | not) |
#     select(test("\\bResolve[sd]?\\s+[#][0-9]+"; "ix") | not) |
#     select(test("\\bRelated\\s+to\\s+[#][0-9]+"; "ix") | not) | 
#     # Indent the lines
#     "  " + .
#   ] |
#   # Join the lines into a single string.
#   join("\n")
#   ;

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

# def pr_to_md:
#   "- [\(.title)](\(.html_url))" as $title_line | 
#   # .body | format_pr_body  as $body |
#   .body | format_pr_body  |
#   # if $body then $lines |= . + [ $body ] end |
#   # if $body then $lines += [ $body ] end |
#   # $lines | join("\n")
#   # if $body then [$title_line, $body] else [$title_line] end |
#   if . then [$title_line, .] else [$title_line] end |
#   join("\n")
#   ;

# def pr_to_md:
#   "- [\(.title)](\(.html_url))" as $title_line | 
#   .body | format_pr_body  as $body |
#   # Handle if body formatting returns empty/null
#   if .body then "\($title_line)\n\(.body | format_pr_body)" else $title_line end
#   ;
