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

- Avoid using `sleep` for more than 60 seconds (1 minute)
- For longer waits, use polling or event-based approaches instead
