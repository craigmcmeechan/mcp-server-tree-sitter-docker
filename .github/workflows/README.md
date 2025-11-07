# GitHub Actions Workflows

This directory contains CI/CD workflows for automated Docker image building, testing, and publishing.

## Available Workflows

### 1. docker-build.yml - Continuous Integration

**Triggers:**
- Push to `main` or `develop` branches
- Pull requests to `main` or `develop`
- Manual dispatch (`workflow_dispatch`)

**What it does:**
- Builds production and dev images (matrix build)
- Runs smoke tests (version, imports, language pack)
- Runs unit tests (dev image only)
- Security scanning with Trivy
- Reports image sizes
- Uploads security results to GitHub Security tab

**Jobs:**
- `build-test`: Build and test both image variants
- `build-multiplatform`: Build for amd64 and arm64 (on main branch only)

**Matrix Strategy:**
```yaml
matrix:
  target: [production, dev]
```

### 2. docker-publish.yml - Release Publishing

**Triggers:**
- Git tags matching `v*.*.*` (e.g., v0.6.0)
- GitHub releases published
- Manual dispatch with tag input

**What it does:**
- Builds multi-platform images (linux/amd64, linux/arm64)
- Pushes to Docker Hub
- Creates semantic version tags (e.g., v0.6.0, v0.6, v0)
- Publishes both production and dev variants
- Updates Docker Hub repository description
- Generates release notes in workflow summary

**Required Secrets:**
- `DOCKER_HUB_USERNAME` - Docker Hub username
- `DOCKER_HUB_TOKEN` - Docker Hub access token

**Image Tags Created:**
```
Production:
  - username/mcp-server-tree-sitter:latest
  - username/mcp-server-tree-sitter:0.6.0
  - username/mcp-server-tree-sitter:0.6
  - username/mcp-server-tree-sitter:0

Development:
  - username/mcp-server-tree-sitter:dev
  - username/mcp-server-tree-sitter:0.6.0-dev
  - username/mcp-server-tree-sitter:0.6-dev
```

### 3. docker-pr.yml - Pull Request Validation

**Triggers:**
- Pull requests to `main` or `develop` branches

**What it does:**
- Lints Dockerfiles with Hadolint
- Builds both images (no push)
- Runs all tests
- Security scanning (non-blocking)
- Reports image sizes in PR summary
- Posts success comment on PR

**Jobs:**
- `validate-dockerfile`: Lint Dockerfiles
- `build-and-test`: Build and test images
- `comment-pr`: Add comment to PR with results

**Features:**
- Fast feedback on PR changes
- Non-blocking security scans (informational)
- Automatic PR comments with results
- GitHub Checks integration

## Setup Instructions

### 1. Enable GitHub Actions

1. Go to repository Settings → Actions → General
2. Enable "Allow all actions and reusable workflows"
3. Enable "Read and write permissions" for GITHUB_TOKEN

### 2. Configure Docker Hub

**Create Docker Hub Access Token:**
1. Log in to Docker Hub
2. Go to Account Settings → Security → Access Tokens
3. Create new token with Read & Write permissions
4. Copy the token (you won't see it again)

**Add Secrets to GitHub:**
1. Go to repository Settings → Secrets and variables → Actions
2. Add repository secrets:
   - Name: `DOCKER_HUB_USERNAME`
     Value: Your Docker Hub username
   - Name: `DOCKER_HUB_TOKEN`
     Value: Your access token

### 3. Enable Security Scanning

The Trivy security scanner is integrated by default. Results appear in:
- Workflow logs
- GitHub Security tab (Code scanning alerts)

No additional setup required.

## Workflow Behavior

### On Push to Main

```mermaid
Push to main
    ↓
Build & Test (both variants)
    ↓
Multi-platform Build (amd64, arm64)
    ↓
Cache results for faster subsequent builds
```

### On Tag/Release

```mermaid
Create tag v0.6.0
    ↓
Build multi-platform images
    ↓
Push to Docker Hub
    ├─ latest
    ├─ 0.6.0
    ├─ 0.6
    ├─ 0
    ├─ dev
    └─ 0.6.0-dev
    ↓
Update Docker Hub README
    ↓
Generate release notes
```

### On Pull Request

```mermaid
Open/Update PR
    ↓
Lint Dockerfiles
    ↓
Build images (no push)
    ↓
Run tests
    ↓
Security scan
    ↓
Comment results on PR
```

## Cache Strategy

All workflows use GitHub Actions cache for:
- Docker layer caching
- BuildKit cache
- Faster subsequent builds

**Cache keys:**
- `type=gha` - GitHub Actions cache
- `mode=max` - Cache all layers

**Benefits:**
- ~50-70% faster builds on cache hit
- Reduced build times for PRs
- Lower CI minutes usage

## Manual Workflow Dispatch

All workflows can be triggered manually:

### Via GitHub UI

1. Go to Actions tab
2. Select workflow from left sidebar
3. Click "Run workflow" button
4. Choose branch
5. Fill in any required inputs
6. Click "Run workflow"

### Via CLI

```bash
# Build workflow
gh workflow run docker-build.yml

# Publish workflow with tag
gh workflow run docker-publish.yml -f tag=v0.6.0
```

## Monitoring Workflows

### View Workflow Runs

```bash
# List recent runs
gh run list

# View specific run
gh run view RUN_ID

# Watch run in real-time
gh run watch
```

### Workflow Status Badges

Add to README.md:

```markdown
[![Docker Build](https://github.com/USERNAME/REPO/actions/workflows/docker-build.yml/badge.svg)](https://github.com/USERNAME/REPO/actions/workflows/docker-build.yml)

[![Docker Publish](https://github.com/USERNAME/REPO/actions/workflows/docker-publish.yml/badge.svg)](https://github.com/USERNAME/REPO/actions/workflows/docker-publish.yml)
```

## Troubleshooting

### Build Failures

**Issue**: Build fails with "No space left on device"

**Solution**:
```yaml
# Add to workflow:
- name: Free disk space
  run: |
    docker system prune -af
    docker volume prune -f
```

**Issue**: Cache not working

**Solution**:
- Check cache keys are consistent
- Verify `cache-from` and `cache-to` are set
- Clear cache and rebuild (Settings → Actions → Caches)

### Publish Failures

**Issue**: Docker Hub authentication failed

**Solution**:
- Verify secrets are set correctly
- Check token has write permissions
- Regenerate token if expired

**Issue**: Tag format not recognized

**Solution**:
- Use semantic versioning: `v1.2.3`
- Don't include prefix like `release-`
- Check tag matches pattern in workflow

### Security Scan Issues

**Issue**: High severity vulnerabilities found

**Solution**:
- Update base image: `FROM python:3.10-slim`
- Update dependencies in `pyproject.toml`
- Review Trivy report for specific CVEs

**Issue**: SARIF upload fails

**Solution**:
- Ensure Advanced Security is enabled (public repos)
- Check permissions are correct
- Review workflow logs for specific error

## Best Practices

### Version Tagging

```bash
# Create annotated tag
git tag -a v0.6.0 -m "Release version 0.6.0"

# Push tag to trigger publish
git push origin v0.6.0
```

### PR Workflow

1. Create feature branch
2. Make changes
3. Open PR
4. Wait for PR validation workflow
5. Review automated test results
6. Merge after approval

### Release Workflow

1. Merge all changes to main
2. Update version in `pyproject.toml`
3. Create git tag: `v0.6.0`
4. Push tag
5. Publish workflow runs automatically
6. Verify on Docker Hub
7. Create GitHub release (optional)

### Cache Management

```bash
# View caches
gh cache list

# Delete specific cache
gh cache delete CACHE_ID

# Delete all caches (forces fresh build)
gh cache delete --all
```

## Performance Metrics

**Typical Build Times:**

| Workflow | Without Cache | With Cache | Savings |
|----------|--------------|------------|---------|
| Build & Test | 8-10 min | 3-4 min | ~60% |
| Publish | 15-20 min | 8-10 min | ~50% |
| PR Validation | 6-8 min | 2-3 min | ~65% |

**Multi-platform builds:**
- amd64: ~5-7 minutes
- arm64: ~6-8 minutes
- Total: ~12-15 minutes (parallel)

## Security Considerations

### Secrets Management

✅ **Do:**
- Use GitHub Secrets for credentials
- Rotate tokens regularly
- Use access tokens (not password)
- Limit token permissions

❌ **Don't:**
- Commit credentials to code
- Share secrets in PR comments
- Use personal account for CI
- Grant unnecessary permissions

### Image Security

- Base images updated automatically (via Dependabot)
- Security scans on every build
- Vulnerabilities reported to Security tab
- Non-root user in containers

## Extending Workflows

### Add New Test

```yaml
- name: Custom test
  run: |
    docker run --rm $IMAGE_NAME:tag \
      python -m pytest tests/custom/
```

### Add Deployment Step

```yaml
- name: Deploy to staging
  if: github.ref == 'refs/heads/main'
  run: |
    # Your deployment script
```

### Add Notification

```yaml
- name: Notify Slack
  if: failure()
  uses: 8398a7/action-slack@v3
  with:
    status: ${{ job.status }}
    webhook_url: ${{ secrets.SLACK_WEBHOOK }}
```

## Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Docker Build Push Action](https://github.com/docker/build-push-action)
- [Trivy Security Scanner](https://github.com/aquasecurity/trivy)
- [Hadolint Dockerfile Linter](https://github.com/hadolint/hadolint)

## Support

For issues with workflows:

1. Check workflow logs in Actions tab
2. Review this README
3. Check [GitHub Actions status](https://www.githubstatus.com/)
4. Open issue with workflow logs

---

**Last Updated**: 2025-11-07
**Workflow Version**: 1.0
