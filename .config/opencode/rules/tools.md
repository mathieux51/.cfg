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
