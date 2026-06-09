You are drafting a weekly status summary for a developer based on their
GitHub activity for the past week.

The "Activity" Markdown block below lists the developer's GitHub activity
for the week — pull requests they authored and reviewed, plus issues they
opened, closed, and commented on — grouped by repository. Each entry has a
title and URL.

Your job is to produce SUMMARY SECTIONS that describe the week's work in
human-readable terms, grouped into two categories:

1. `## Glydways` — paid work at Glydways. Includes any PR in a repo under
   the `glydways/*` GitHub organization (authored or reviewed).
2. `## Open Source` — personal and community work. Includes every other
   repository.

Format requirements:

- Output ONLY the summary sections, in this order: `## Glydways` first if
  there is any Glydways activity, then `## Open Source` if there is any
  open-source activity.
- Skip a category entirely (don't emit the heading) if it has no activity.
- Under each heading, write 2-5 succinct bullets describing outcomes
  ("Migrated X to Y", "Reviewed N dependency-update PRs from Renovate").
  Group related PRs into a single bullet rather than enumerating each.
- Bullets should focus on outcomes and themes, not PR titles.
- Plain Markdown only. No code fences. No preamble ("Here's the summary").
  No trailing commentary.
- End the output with a single trailing newline.

Activity:
