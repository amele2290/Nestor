#!/usr/bin/env sh
set -e

# Simple wait-for-DATABASE_URL + basic TCP check
wait_for_db() {
  if [ -z "$DATABASE_URL" ]; then
    echo "DATABASE_URL is not set. Waiting up to 60s for it..."
    n=0
    until [ $n -ge 30 ]
    do
      if [ -n "$DATABASE_URL" ]; then
        break
      fi
      n=$((n+1))
      sleep 2
    done
  fi

  echo "Checking DB connectivity..."
  # Try a simple node-based check to avoid requiring psql client.
  n=0
  until [ $n -ge 30 ]
  do
    node -e "require('pg').connect ? console.log('pg module available') : console.log('no pg')" >/dev/null 2>&1 || true
    # Try to run a small JS connection test
    node -e "const { Client } = require('pg'); (async()=>{ try { const c=new Client({ connectionString: process.env.DATABASE_URL }); await c.connect(); await c.end(); console.log('OK'); process.exit(0);} catch(e){ process.exit(1);} })()" >/dev/null 2>&1 && break || true
    n=$((n+1))
    echo "Waiting for DB to accept connections... ($n/30)"
    sleep 2
  done
}

run_migrations_and_seed() {
  if [ -f ./prisma/schema.prisma ]; then
    echo "Detected Prisma schema. Running migrations and seed..."
    # ensure client is generated
    npx prisma generate
    npx prisma migrate deploy
    # run seed if defined (npx prisma db seed uses prisma/seed.ts or package.json seed)
    npx prisma db seed || true
    return
  fi

  # TypeORM (assumes scripts exist)
  if grep -q "typeorm" package.json 2>/dev/null || [ -f ormconfig.js ] || [ -f ormconfig.json ]; then
    echo "Detected TypeORM. Running migrations & seed via npm scripts..."
    npm run typeorm:migration:run || npm run migration:run || true
    npm run seed || true
    return
  fi

  # SQL seed fallback (if seed/seed.sql exists and psql exists)
  if [ -f ../seed/seed.sql ] || [ -f ./seed/seed.sql ]; then
    echo "Found seed/seed.sql. Attempting to run via psql client (if installed)..."
    if command -v psql >/dev/null 2>&1; then
      PSQL_CONN="$DATABASE_URL"
      psql "$PSQL_CONN" -f ../seed/seed.sql || psql "$PSQL_CONN" -f ./seed/seed.sql || true
    else
      echo "psql not installed in container — skip SQL seed. Consider using Prisma/TypeORM seed scripts."
    fi
  fi
}

start_app() {
  echo "Starting NestJS app..."
  # Ensure your built file is at dist/main.js
  exec node dist/main.js
}

wait_for_db
run_migrations_and_seed
start_app
