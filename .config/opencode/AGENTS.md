# Python Rules

Always use `uv` for Python operations:

- Use `uv run` instead of `python` to execute scripts
- Use `uv pip install` instead of `pip install`
- Use `uv sync` for dependency management
- Use `uv init` to create new Python projects
- Use `uv add` to add dependencies to pyproject.toml

# OpenTofu Rules

Always use `tofu` (OpenTofu) instead of `terraform`:

- Use `tofu init` instead of `terraform init`
- Use `tofu plan` instead of `terraform plan`
- Use `tofu apply` instead of `terraform apply`
- Use `tofu destroy` instead of `terraform destroy`
- Use `tofu fmt` instead of `terraform fmt`
- Use `tofu validate` instead of `terraform validate`

# Sleep Rules

- NEVER use `sleep` for more than 60 seconds (1 minute). This is a hard requirement.
- If you need to wait longer than 60 seconds, you MUST use polling with shorter intervals or event-based approaches instead
- Example: Instead of `sleep 300`, use a loop like `for i in {1..5}; do sleep 60 && echo "Waited $i minute(s)..."; done`

# GCP Secrets Rules

Always use GCP Secret Manager to search for and retrieve secrets:

- When you need to find a secret or are unsure of its exact name, proactively run `gcloud secrets list --filter="<keyword>"` to search for it
- Use `gcloud secrets list` to list all available secrets
- Use `gcloud secrets versions access latest --secret=<SECRET_NAME>` to retrieve secret values
- Use `gcloud secrets describe <SECRET_NAME>` to get secret metadata
- Never hardcode secrets in code or configuration files
- When a secret is needed, always check GCP Secret Manager first
- If a task involves credentials, API keys, tokens, or any sensitive value, assume it is stored in GCP Secret Manager and search for it there before asking the user

# Kubernetes Rules

When checking pods in Kubernetes:

- Use `kubectl get pods` to list pods (add `-A` or `--all-namespaces` to see all namespaces)
- Use `kubectl describe pod <POD_NAME>` to get detailed pod information
- Use `kubectl logs <POD_NAME>` to view pod logs (add `-f` to follow)
- Use `kubectl get pods -o wide` to see additional details like node and IP
- Always specify the namespace with `-n <NAMESPACE>` when working with a specific namespace

# Task Progress Documentation Rules

For large or complex tasks, document progress in the `docs/` folder:

- Create a markdown file in `docs/` to track progress (e.g., `docs/task-<name>.md` or `docs/progress-<feature>.md`)
- Include the following sections in the document:
  - **Objective**: What the task aims to accomplish
  - **Progress**: Checklist of steps with completion status
  - **Decisions**: Key decisions made during implementation
  - **Issues**: Any blockers or problems encountered
  - **Next Steps**: What remains to be done
- Update the document as you complete each step of the task
- Mark completed items with `[x]` and pending items with `[ ]`
- Add timestamps or dates for significant milestones
- Keep the document updated throughout the task, not just at the end

# Git Commit Rules

Always reference Linear tickets in commit messages:

- Before creating a commit, ask for the Linear ticket link/ID if not already provided
- Include the Linear ticket ID in the commit message description (e.g., `Fixes ENG-123` or `Relates to ENG-456`)
- Format: Use the ticket ID in the commit body, not just the title
- Example commit message:
  ```
  feat: add user authentication flow
  
  Implements OAuth2 login with Google provider.
  
  Fixes ENG-123
  ```
- If no Linear ticket exists for the work, ask if one should be created or if the commit should proceed without a reference

# CI Rules

- NEVER wait for CI pipelines to complete. After pushing changes or creating a PR, move on immediately.
- Do not poll, watch, or monitor CI status.
- Do not block on CI checks, build results, or test results from remote pipelines.
