# MOM CRUD Laravel CI/CD

Production-grade CI/CD setup for a Laravel application deployed to AWS EC2 with regression testing, separated environments, CodeBuild packaging, and CodeDeploy deployment.

## Architecture

```text
Developer
  |
  | push feature/*, develop, or main
  v
GitHub
  |
  | GitHub Actions / CircleCI
  | - install PHP dependencies
  | - prepare isolated test environment
  | - migrate test database
  | - run PHPUnit regression tests
  v
AWS CodePipeline
  |
  | source stage from GitHub/CodeStar connection
  v
AWS CodeBuild
  |
  | buildspec.yml
  | - install Composer dependencies
  | - run tests
  | - build frontend assets
  | - prepare CodeDeploy artifact
  v
AWS CodeDeploy
  |
  | appspec.yml + deploy.sh
  | - copy artifact to EC2
  | - run migrations
  | - cache config/routes/views
  | - restart web services
  v
EC2 /var/www/html/mom-crud
```

## Regression Testing

The Employee CRUD regression suite is in `tests/Feature/EmployeeTest.php`.

It uses Laravel `RefreshDatabase` so each test starts with a clean database. The suite covers:

- Create employee with valid data
- Create employee validation failures
- Duplicate email validation
- Employee index and show pages
- Update employee with valid data
- Update validation errors
- Delete employee

Run locally:

```bash
cp .env.ci .env
touch database/database.sqlite
php artisan key:generate --force
php artisan migrate --force
php artisan test
```

## GitHub Actions

Workflow: `.github/workflows/ci.yml`

The CI job runs on `feature/**`, `develop`, `main`, and pull requests into `develop` or `main`.

Pipeline steps:

1. Checkout source.
2. Setup PHP 8.2.
3. Install Composer dependencies with cache.
4. Copy `.env.ci` to `.env`.
5. Create SQLite test database.
6. Generate `APP_KEY`.
7. Run migrations.
8. Run `php artisan test`.

If tests fail, the job fails and deployment jobs do not run.

Optional deployment triggers:

- `feature/**` and `develop` start the staging CodePipeline.
- `main` starts the production CodePipeline.

Required GitHub secrets:

- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `AWS_REGION`
- `AWS_STAGING_PIPELINE_NAME`
- `AWS_PRODUCTION_PIPELINE_NAME`

## CircleCI

Workflow: `.circleci/config.yml`

CircleCI uses:

- `cimg/php:8.2`
- `cimg/mysql:8.0`

Pipeline steps:

1. Install Composer dependencies.
2. Copy `.env.ci`.
3. Generate app key.
4. Wait for MySQL.
5. Run migrations.
6. Run PHPUnit and store JUnit results.
7. Trigger staging or production CodePipeline after tests pass.

Required CircleCI environment variables:

- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `AWS_REGION`
- `AWS_STAGING_PIPELINE_NAME`
- `AWS_PRODUCTION_PIPELINE_NAME`

## AWS CodePipeline

Recommended stages:

1. Source: GitHub via CodeStar connection.
2. Build: CodeBuild project using `buildspec.yml`.
3. Deploy: CodeDeploy EC2 deployment group using `appspec.yml`.

Use separate pipelines or deployment groups:

- Staging: source branch `develop` and optionally `feature/**`
- Production: source branch `main`

## CodeBuild

File: `buildspec.yml`

CodeBuild installs PHP 8.2 and Node.js 20, installs dependencies, runs migrations against SQLite, runs PHPUnit, builds frontend assets, removes local `.env`, and emits a CodeDeploy artifact containing the Laravel app, vendor dependencies, `appspec.yml`, and `deploy.sh`.

Tests run before production dependencies are optimized. This keeps dev-only test packages available during test execution and removes them before artifact creation.

## CodeDeploy

File: `appspec.yml`

CodeDeploy copies the artifact to:

```text
/var/www/html/mom-crud
```

Then it runs:

```text
deploy.sh
```

The deployment script:

- Logs to `/var/log/mom-crud`
- Detects staging or production from the deployment group name when available
- Uses CodeDeploy artifacts by default
- Pulls latest Git code only if `/var/www/html/mom-crud/.git` exists
- Loads environment config
- Runs `composer install --no-dev`
- Runs `php artisan migrate --force`
- Clears and rebuilds Laravel caches
- Sets storage permissions
- Restarts PHP-FPM and Apache or Nginx
- Takes the app out of maintenance mode if a failure occurs

## Environment Separation

Templates are committed for structure only:

- `.env.dev`
- `.env.staging`
- `.env.production`
- `.env.ci`

Do not store real production secrets in Git. On EC2, place real environment files here:

```text
/etc/mom-crud/.env.staging
/etc/mom-crud/.env.production
```

The deployment script loads those files first. If they do not exist, it falls back to the repository template.

Pipeline switching:

- CI uses `.env.ci`.
- Staging deployment uses `DEPLOYMENT_GROUP_NAME` containing `staging`, or `DEPLOY_ENV=staging`.
- Production deployment uses `DEPLOYMENT_GROUP_NAME` containing `production`, or `DEPLOY_ENV=production`.

## Branching Strategy

Use this flow:

```text
feature/my-change -> CI tests -> staging deployment
develop           -> CI tests -> staging deployment
main              -> CI tests -> production deployment
```

Recommended team practice:

1. Create work on `feature/*`.
2. Push feature branch to run regression tests and deploy to staging.
3. Open a pull request into `develop`.
4. Merge `develop` into `main` only after staging validation.
5. Push or merge into `main` to deploy production.

## Deployment Trigger

GitHub Actions and CircleCI both trigger AWS CodePipeline after tests pass. You can also trigger manually:

```bash
aws codepipeline start-pipeline-execution --name "$AWS_STAGING_PIPELINE_NAME"
aws codepipeline start-pipeline-execution --name "$AWS_PRODUCTION_PIPELINE_NAME"
```

## Rollback

Use CodeDeploy rollback:

- Enable automatic rollback on deployment failure.
- Enable automatic rollback on CloudWatch alarm breach.
- Keep the previous successful deployment revision in CodeDeploy/S3.

Manual rollback:

```bash
aws deploy create-deployment \
  --application-name MOM-CRUD \
  --deployment-group-name production \
  --revision revisionType=S3,s3Location="{bucket=mom-crud-artifacts,key=previous-artifact.zip,bundleType=zip}"
```

Database migrations should be backward-compatible. Avoid destructive schema changes in the same release as application code that depends on them.

## Best Practices

- Store secrets in GitHub Secrets, CircleCI contexts, AWS SSM Parameter Store, or AWS Secrets Manager.
- Keep real `.env` files outside the repository on EC2.
- Use `composer install --no-dev --optimize-autoloader --classmap-authoritative` for deployed artifacts.
- Cache Laravel config, routes, and views after deployment.
- Use CodeDeploy rolling or blue/green deployments to reduce downtime.
- Keep migrations forward-compatible.
- Monitor deployment logs in `/var/log/mom-crud`.
- Use CloudWatch alarms for 5xx rates, CPU, memory, disk, and health checks.
