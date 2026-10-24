#!/usr/bin/env node
// LOCAL STACK ONLY. Sets the newest emailed sign-in code of <email> to <code>
// so integration tests can complete the code step without reading mail.
// Usage: node force_otp_code.mjs <backend.env> <email> <code>
// Refuses any DATABASE_URL that is not on 127.0.0.1.
import { readFileSync } from 'node:fs';
import { createHmac, hkdfSync } from 'node:crypto';
import { execFileSync } from 'node:child_process';

const [envPath, email, code] = process.argv.slice(2);
if (!envPath || !email || !/^\d{6}$/.test(code ?? '')) {
  console.error('usage: force_otp_code.mjs <backend.env> <email> <6-digit code>');
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
const root = Buffer.from(env.PAYMENT_CREDENTIALS_ENCRYPTION_KEY, 'hex');
const key = Buffer.from(hkdfSync('sha256', root, 'atlas.auth.challenge.hkdf.salt.v1',
  'atlas.auth.challenge.code.v1', 32));
const psql = (sql) => execFileSync('psql', [db, '-Atc', sql], { encoding: 'utf8' }).trim();
const safeEmail = email.replace(/'/g, "''");
const row = psql(`SELECT c.id || '|' || c.salt FROM auth_email_challenges c
  JOIN users u ON u.id = c.user_id WHERE lower(u.email) = lower('${safeEmail}')
  ORDER BY c.created_at DESC LIMIT 1`);
if (!row) { console.error('no challenge for that email'); process.exit(1); }
const [id, salt] = row.split('|');
const hash = createHmac('sha256', key).update(`${id}.${salt}.${code}`).digest('hex');
psql(`UPDATE auth_email_challenges SET code_hash = '${hash}' WHERE id = '${id}'`);
console.log(`challenge ${id} now accepts ${code}`);
