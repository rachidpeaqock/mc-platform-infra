#!/usr/bin/env bash
#
# Brings a Codespace to the point where the product is running.
#
# Runs once, on creation. Everything here is idempotent so it can be
# re-run by hand after a rebuild:  bash .devcontainer/setup.sh
set -euo pipefail

WORKSPACE="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
INFRA="$WORKSPACE/mc-platform-infra"

echo "==> Cloning the sibling repos"
# compose.yml mounts ../mc-milestone-service for the migration SQL, and the
# apps live in their own repos. A Codespace checks out one repo, so the
# rest are fetched here — using the token GitHub granted via the
# `repositories` block in devcontainer.json.
for repo in mc-milestone-service mc-dashboards mc-shell mc-templates mc-field; do
  if [ -d "$WORKSPACE/$repo/.git" ]; then
    echo "    $repo already present"
  else
    gh repo clone "rachidpeaqock/$repo" "$WORKSPACE/$repo" -- --depth 1 \
      && echo "    cloned $repo" \
      || echo "    !! could not clone $repo — authorise it in the Codespace's repository access"
  fi
done

echo "==> Signing in to GHCR"
# The service images are private. GITHUB_TOKEN carries packages:read from
# the devcontainer's repository grants.
echo "${GITHUB_TOKEN:-}" | docker login ghcr.io -u "${GITHUB_USER:-$USER}" --password-stdin \
  || echo "    !! GHCR login failed — `docker compose up` will not be able to pull the services"

echo "==> Starting the platform"
cd "$INFRA"
docker compose up -d postgres kafka discovery-server api-gateway

echo "==> Migrating the database"
# Flyway's own image: no Maven, no JDK. The service refuses to start
# against an un-migrated database (MC-304), so this is not optional.
docker compose --profile migrate run --rm migrate

echo "==> Starting the milestone service"
docker compose up -d milestone-service

echo "==> Installing front-end dependencies"
# @rachidpeaqock/design-system is a private package on GitHub Packages.
cd "$WORKSPACE/mc-dashboards"
cat > .npmrc <<EOF
@rachidpeaqock:registry=https://npm.pkg.github.com
//npm.pkg.github.com/:_authToken=${GITHUB_TOKEN:-}
EOF
npm ci || npm install

cat <<'DONE'

============================================================
  Ready.

    cd ../mc-dashboards && npm start -- --host 0.0.0.0

  Then open the forwarded port 4200.

  TWO THINGS BEFORE IT WILL SIGN IN:

  1. Make port 8080 PUBLIC in the Ports panel. The browser runs on your
     machine and calls the gateway over the internet; a private port
     answers with a GitHub login page.

  2. The Codespace's 4200 URL must be registered as an Entra redirect
     URI. It is unique to this Codespace, so it cannot be pre-registered
     — send it to Claude, or add it yourself under the
     "Milestone Command Web" app registration, SPA platform.
============================================================
DONE
