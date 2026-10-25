#!/usr/bin/env node
// LOCAL STACK ONLY. Makes the newest emailed reset or verification link of
// <email> accept <token>, so integration tests can follow the link without
// reading mail. Usage:
//   node force_link_token.mjs <backend.env> <email> <reset|verify> <token>
// Refuses any DATABASE_URL that is not on 127.0.0.1.
import { readFileSync } from 'node:fs';
import { createHash } from 'node:crypto';
import { execFileSync } from 'node:child_process';

const [envPath, email, kind, token] = process.argv.slice(2);
const table = { reset: 'password_reset_tokens', verify: 'email_verification_tokens' }[kind];
if (!envPath || !email || !table || !/^[A-Za-z0-9_-]{16,}$/.test(token ?? '')) {
  console.error('usage: force_link_token.mjs <backend.env> <email> <reset|verify> <token>');
  process.exit(2);
}
const env = Object.fromEntries(
  readFileSync(envPath, 'utf8').split('\n')
    .filter((l) => /^[A-Z0-9_]+=/.test(l))
    .map((l) => [l.slice(0, l.indexOf('=')), l.slice(l.indexOf('=') + 1)]),
);
const db = env.DATABASE_URL ?? '';
if (!/@127\.0\.0\.1:\d+\//.test(db)) {
  console.error(`REFUSING: ${db} is not a 127.0.0.1 database`);
  process.exit(2);
}
const psql = (sql) => execFileSync('psql', [db, '-Atc', sql], { encoding: 'utf8' }).trim();
const safeEmail = email.replace(/'/g, "''");
const id = psql(`SELECT t.id FROM ${table} t JOIN users u ON u.id = t.user_id
  WHERE lower(u.email) = lower('${safeEmail}') AND t.used_at IS NULL
  ORDER BY t.created_at DESC LIMIT 1`);
const hash = createHash('sha256').update(token).digest('hex');
if (!id && kind === 'verify') {
  // An emailed-code sign-in already verified the address and retired the
  // link; issue a fresh one, as the resend endpoint would for an
  // unverified account.
  const created = psql(`INSERT INTO ${table} (id, user_id, token_hash, expires_at)
    SELECT gen_random_uuid(), u.id, '${hash}', now() + interval '1 day' FROM users u
    WHERE lower(u.email) = lower('${safeEmail}') RETURNING id`);
  if (!created) { console.error('no user with that email'); process.exit(1); }
  console.log(`verify link ${created} created for the given token`);
  process.exit(0);
}
if (!id) { console.error(`no unused ${kind} link for that email`); process.exit(1); }
psql(`UPDATE ${table} SET token_hash = '${hash}' WHERE id = '${id}'`);
console.log(`${kind} link ${id} now accepts the given token`);
