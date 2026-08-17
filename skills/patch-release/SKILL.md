---
name: patch-release
description: Plan a patch release from recent issues. Triages what belongs in a patch, proposes a batch for approval, then opens a tracking issue with the version number, draft release notes and a checklist. Use when asked to plan or scope a patch release, cut a bugfix release, or work out what should go into the next x.y.Z.
---

# Planning a patch release

The loop this supports: survey recent issues, agree a batch, record it as a
tracking issue, work through it as normal PRs, then the human cuts the
release.
Your job is the first half.
You do not tag, publish, or register anything.

Delegate the survey work.
Reading and classifying issues is mechanical, so use
`productivity:weak-general-purpose` subagents, several in parallel, one per
slice of the issue list.
Keep the judgement — what belongs in a patch — for yourself.

## 1. Establish where the last release ended

```bash
gh release list -R <repo> --limit 5
git -C <repo> log --oneline "$(git describe --tags --abbrev=0)"..HEAD
```

That commit range matters as much as the issues.
Anything already merged and unreleased belongs in the notes whether or not
it came from an issue in this batch.

Current version, by project type:

| Type | Where | Notes |
|---|---|---|
| R package | `DESCRIPTION`, `Version:` | changelog is `NEWS.md` |
| Julia package | `Project.toml`, `version =` | released by Registrator + TagBot |
| Anything else | latest git tag | |

The new version is the patch component incremented, nothing else.

## 2. Triage recent issues

```bash
gh issue list -R <repo> --state open --limit 60 \
  --json number,title,labels,updatedAt,author
```

A patch release fixes things.
Sort each issue into one of three piles and be strict about the middle one:

- **In scope**: bug fixes, incorrect results, crashes, documentation
  corrections, dependency and CI repairs, internal changes with no
  user-visible behaviour change.
- **Out of scope**: anything that adds a feature, changes an interface, or
  alters documented behaviour. That is a minor release. Say so and leave it
  out rather than quietly widening the patch.
- **Too big**: a fix that needs design work or touches a model's structure.
  Name it, exclude it, and say why.

Prefer issues that are already understood.
An issue with a diagnosis in the thread is patch material; one that still
needs investigating is a research task that happens to be labelled a bug.

## 3. Propose the batch and stop

Present, and wait for approval:

- the proposed version number and what the current one is
- the in-scope issues in the order they should be done, with a sentence
  each on what the fix involves
- what you excluded and why, especially anything you judged minor rather
  than patch
- work already merged since the last release, which the notes must cover
- anything where you are unsure which pile it belongs in

Do not create the tracking issue before approval.
Do not start fixing anything.

## 4. Record the agreed batch

Once approved, open one tracking issue.
Title it with the version, e.g. `Release 1.4.3`.
Body:

- **Draft release notes**, grouped as the project already groups them —
  match the existing `NEWS.md` or previous GitHub releases rather than
  inventing headings. Cover the merged-but-unreleased work as well as the
  planned fixes. Write them as user-facing statements, not as a list of
  issue titles.
- **A checklist**, one line per in-scope issue, `- [ ] #123 short
  description`, in the agreed order.
- **What was deferred**, with the reason, so the decision is recorded
  rather than remembered.

Notes are a draft on purpose.
Each merged PR may change its own line, and the human rewrites them at
release time.

## 5. Then work the batch

Each checklist item is a normal PR through the usual flow: issue, branch or
worktree, tests, review.
Tick the box when it merges and keep the notes in the tracking issue current
as you go.

The release itself is the human's: bumping the version, finalising the
notes, tagging, and for Julia commenting `@JuliaRegistrator register`.
Never do those, and never open a PR that bumps the version unless asked.
