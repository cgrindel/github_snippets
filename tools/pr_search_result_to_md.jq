def pr_to_md:
  "- [\(.title)](\(.html_url))"
  ;

.items[] | pr_to_md
