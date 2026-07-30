---
name: explain-v2
description: Use when the user asks for a rich, interactive HTML explanation of a code change, diff, branch, or PR — especially when interactive flow/architecture diagrams and progressive disclosure (concise by default, drill in for detail) would help. This is the successor to explain-diff-html; prefer it unless the user specifically wants the older, flatter format.
---

# Explain Diff v2

Please make me a rich, interactive explanation of the specified code change. Two things distinguish this from a plain writeup:

1. **Interactive diagrams of code flow**, especially where execution crosses abstraction layers, module/service boundaries, or touches an invariant the system relies on.
2. **Progressive disclosure everywhere.** The default view is concise — a reader who skims should get the gist in under a minute. Every section should let someone drill in for the full story: code, edge cases, why it's built this way.

## Sections

- **Background**: Explain the existing system relevant to this change. Explore surrounding code broadly before writing this. Give a short (2-4 sentence) "what you need to know" summary that's always visible, then put the deeper background — the stuff a newcomer needs but a familiar reader would skip — behind a collapsed `<details>`/toggle. Don't make the reader page through beginner context to get to the point.
- **Intuition**: Explain the core idea of the change — essence over detail. Concrete examples with toy data. This is usually short enough it doesn't need its own disclosure toggle, but keep it tight regardless.
- **Flow**: One or more interactive diagrams tracing the actual code path(s) touched by this change — see "Diagramming code flow" below. This is the section this skill exists for; don't skimp on it.
- **Code**: A high-level walkthrough of the changes, grouped/ordered for understanding rather than by file. Show short excerpts inline; put full before/after hunks behind a toggle per group so the walkthrough reads as prose, not a raw diff dump.
- **Quiz**: Five interactive multiple-choice questions, medium difficulty — hard enough that you need to actually understand the change to answer, not gotchas. Clicking an answer reveals immediately whether it's correct, with a one-line explanation why.

## Diagramming code flow

The goal is to make the reader's mental model of "how does this actually execute" visible and explorable, not just described in prose.

- Pick the smallest number of diagrams that cover the change's important paths. One good diagram beats three redundant ones. Reuse the same visual vocabulary (shapes, colors, line styles) across all of them so the reader only has to learn it once.
- Draw the path as a sequence of nodes (functions, components, services, queues — whatever the real unit is) connected by arrows for calls or data flow. Mark data direction and, where it clarifies things, the shape of the data itself (a toy payload, not just a type name).
- **Boundaries are the point.** Explicitly render the lines a call crosses: client/server, sync/async, process/thread, module A/module B, trusted/untrusted input. A dashed vertical or horizontal band with a label is usually enough. These are the places bugs and misunderstandings live — don't let them disappear into a uniform box-and-arrow diagram.
- **Surface invariants at the point they matter.** If a step only works because "the lock is held," "the cache was just invalidated," "this list is sorted," or similar, annotate it right on the diagram (a small warning/pin icon works well) rather than burying it in a paragraph below.
- Build it as real HTML/SVG elements (absolutely-positioned divs with connecting lines, or inline `<svg>`), never `<pre>` ASCII art or an external rendering service — it needs to be inspectable, stylable, and able to host hover/click behavior.
- Add a compact legend once, near the first diagram, explaining the visual language (what a box means, what a dashed boundary means, what the warning icon means).

## Progressive disclosure — how to implement it

Default to concise; let the reader ask for more.

- **Hover = a quick popover.** A node or inline term gets a one-to-two sentence tooltip on hover (or tap on touch) — just enough to answer "what is this" without leaving the diagram. Position it near the cursor/element and dismiss on mouse-leave.
- **Click = drill-in.** Clicking a diagram node, a collapsed background section, or a code group expands an inline panel with the full detail: code excerpt, deeper explanation, edge cases, links to the relevant part of the diff. Prefer expanding in place over a modal so the reader keeps their context.
- **Don't force a global mode toggle** ("simple/detailed" switch for the whole page) unless it's clearly useful — per-section/per-node disclosure controlled by the reader is usually better than an all-or-nothing switch, since different readers want depth in different places.
- Use native `<details>`/`<summary>` where a plain collapsible block will do; reach for custom JS popovers only where you need hover behavior or positioning `<details>` can't give you.
- Never hide something *essential* to following the main thread behind a toggle — disclosure is for depth and edge cases, not for load-bearing plot points.

## Format

- Output a single self-contained HTML file with embedded CSS and JS — no external requests. One long page with section headers and a table of contents; don't use tabs for top-level structure. Basic responsive styling so it's readable on a phone.
- Support both light and dark viewing: don't hardcode a light-only palette — respect `prefers-color-scheme` at minimum.
- Save the file in a global place outside the code repo, filename always starting with today's date in `YYYY-MM-DD-` format (keeps files time-sorted and out of version control), e.g. `/tmp/2026-01-12-explanation-<slug>.html`.
- Write with the clarity and flow of Martin Kleppmann — engaging, classic style, smooth transitions between sections.
- For code blocks, always use `<pre>` tags. If you use a custom styled div instead of `<pre>`, it **must** have `white-space: pre-wrap` in its CSS, or the browser will collapse all newlines into a single line. Before saving, scan every code block in the HTML source and confirm its CSS includes `white-space: pre` or `pre-wrap`.
- Use callouts for key concepts, definitions, and important edge cases — these can stay always-visible even where surrounding detail is collapsed, since they're usually short.
