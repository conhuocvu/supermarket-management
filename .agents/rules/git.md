---
trigger: model_decision
description: Use this rule when creating branches, writing commit messages, opening pull requests, merging code, reviewing changes, or following the project's Git workflow and naming conventions.
---

# Git Workflow

This document defines the Git workflow for the project.

All contributors should follow these conventions.

---

# 1. Branches

main

- Production-ready code.
- Protected branch.

dev

- Integration branch.
- All completed features are merged here first.

feature/<feature-name>

- New features.

fix/<bug-name>

- Bug fixes.

hotfix/<issue-name>

- Critical production fixes.

---

# 2. Branch Naming

Examples

feature/login

feature/product-management

feature/order-history

feature/inventory

fix/login-validation

fix/cart-total

hotfix/payment-error

Use lowercase.

Separate words using hyphens.

---

# 3. Development Flow

1.

Create a feature branch from dev.

↓

2.

Develop the feature.

↓

3.

Commit changes.

↓

4.

Push branch.

↓

5.

Create Pull Request.

↓

6.

Review.

↓

7.

Merge into dev.

↓

8.

Merge dev into main for releases.

Never commit directly to main.

---

# 4. Commit Convention

Format

type: short description

Examples

feat: add product CRUD

fix: resolve login validation

docs: update README

style: format source code

refactor: simplify inventory service

test: add authentication tests

chore: update dependencies

---

Supported Types

feat

fix

docs

style

refactor

test

perf

build

ci

chore

---

# 5. Commit Rules

One commit should represent one logical change.

Avoid

"update"

"fix"

"change"

Good examples

feat: add inventory search

fix: prevent duplicate orders

refactor: extract product service

---

# 6. Pull Requests

Each Pull Request should

- solve one problem
- compile successfully
- pass all tests
- follow project rules

Large Pull Requests should be split into smaller ones.

---

# 7. Code Review

Reviewers should verify

- architecture
- readability
- maintainability
- naming
- duplicated code
- responsiveness
- error handling

---

# 8. Before Pushing

Always

- run formatter
- remove debug logs
- remove commented code
- verify analyzer warnings
- verify project builds successfully

---

# 9. Merge Strategy

Use

Squash and Merge

or

Rebase and Merge

Avoid unnecessary merge commits unless preserving history is required.

---

# 10. Source of Truth

All contributors and AI assistants MUST follow this workflow unless explicitly instructed otherwise.