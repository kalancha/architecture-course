import { createClient } from '@clickhouse/client';
import cors from 'cors';
import express from 'express';
import { createRemoteJWKSet, jwtVerify } from 'jose';

const port = Number(process.env.PORT || 8000);
const keycloakIssuer = process.env.KEYCLOAK_ISSUER || 'http://localhost:8080/realms/reports-realm';
const keycloakJwksUrl =
  process.env.KEYCLOAK_JWKS_URL ||
  'http://keycloak:8080/realms/reports-realm/protocol/openid-connect/certs';

const jwks = createRemoteJWKSet(new URL(keycloakJwksUrl));

const clickhouse = createClient({
  url: process.env.CLICKHOUSE_URL || 'http://clickhouse:8123',
  database: process.env.CLICKHOUSE_DATABASE || 'bionicpro',
  username: process.env.CLICKHOUSE_USER || 'default',
  password: process.env.CLICKHOUSE_PASSWORD || ''
});

const app = express();
app.use(
  cors({
    origin: process.env.CORS_ORIGIN || 'http://localhost:3000',
    allowedHeaders: ['Authorization', 'Content-Type']
  })
);
app.use(express.json());

const datePattern = /^\d{4}-\d{2}-\d{2}$/;

async function queryJson(query, query_params = {}) {
  const result = await clickhouse.query({
    query,
    query_params,
    format: 'JSONEachRow'
  });
  return result.json();
}

function normalizeNumber(value) {
  return typeof value === 'number' ? value : Number(value || 0);
}

async function authenticate(req, res, next) {
  const header = req.header('authorization') || '';
  const [scheme, token] = header.split(' ');

  if (scheme !== 'Bearer' || !token) {
    return res.status(401).json({ error: 'Missing bearer token' });
  }

  try {
    const { payload } = await jwtVerify(token, jwks, {
      issuer: keycloakIssuer
    });
    req.user = {
      subject: payload.sub,
      username: payload.preferred_username || payload.sub
    };
    return next();
  } catch (error) {
    return res.status(401).json({ error: 'Invalid bearer token' });
  }
}

async function latestProcessedPeriod() {
  const rows = await queryJson(`
    SELECT
      toString(period_start) AS period_start,
      toString(period_end) AS period_end
    FROM etl_runs
    WHERE status = 'success'
    ORDER BY processed_at DESC
    LIMIT 1
  `);
  return rows[0] || null;
}

async function ensurePeriodIsReady(from, to) {
  const rows = await queryJson(
    `
    SELECT count() AS ready
    FROM etl_runs
    WHERE status = 'success'
      AND period_start <= toDate({from:String})
      AND period_end >= toDate({to:String})
    `,
    { from, to }
  );
  return normalizeNumber(rows[0]?.ready) > 0;
}

app.get('/health', async (_req, res) => {
  try {
    await queryJson('SELECT 1 AS ok');
    res.json({ status: 'ok' });
  } catch (error) {
    res.status(503).json({ status: 'error', error: 'ClickHouse is unavailable' });
  }
});

app.get('/reports', authenticate, async (req, res) => {
  let { from, to } = req.query;

  if ((from && !datePattern.test(String(from))) || (to && !datePattern.test(String(to)))) {
    return res.status(400).json({ error: 'Dates must use YYYY-MM-DD format' });
  }

  try {
    if (!from || !to) {
      const latestPeriod = await latestProcessedPeriod();
      if (!latestPeriod) {
        return res.status(404).json({ error: 'Report period is not ready' });
      }
      from = latestPeriod.period_start;
      to = latestPeriod.period_end;
    }

    const ready = await ensurePeriodIsReady(String(from), String(to));
    if (!ready) {
      return res.status(404).json({ error: 'Report period is not ready' });
    }

    const rows = await queryJson(
      `
      SELECT
        username,
        any(full_name) AS full_name,
        prosthesis_id,
        any(model) AS model,
        toString(min(report_date)) AS period_from,
        toString(max(report_date)) AS period_to,
        sum(total_usage_seconds) AS total_usage_seconds,
        sum(total_movements) AS total_movements,
        avg(avg_battery_level) AS avg_battery_level,
        sum(total_errors) AS total_errors
      FROM report_mart
      WHERE username = {username:String}
        AND report_date BETWEEN toDate({from:String}) AND toDate({to:String})
      GROUP BY username, prosthesis_id
      ORDER BY prosthesis_id
      `,
      {
        username: req.user.username,
        from: String(from),
        to: String(to)
      }
    );

    const reports = rows.map((row) => ({
      prosthesisId: row.prosthesis_id,
      model: row.model,
      period: {
        from: row.period_from,
        to: row.period_to
      },
      totalUsageSeconds: normalizeNumber(row.total_usage_seconds),
      totalMovements: normalizeNumber(row.total_movements),
      averageBatteryLevel: Number(normalizeNumber(row.avg_battery_level).toFixed(2)),
      totalErrors: normalizeNumber(row.total_errors)
    }));

    const totals = reports.reduce(
      (acc, report) => ({
        totalUsageSeconds: acc.totalUsageSeconds + report.totalUsageSeconds,
        totalMovements: acc.totalMovements + report.totalMovements,
        totalErrors: acc.totalErrors + report.totalErrors
      }),
      { totalUsageSeconds: 0, totalMovements: 0, totalErrors: 0 }
    );

    return res.json({
      status: 'ready',
      user: {
        username: req.user.username,
        fullName: rows[0]?.full_name || null
      },
      period: {
        from: String(from),
        to: String(to)
      },
      reports,
      totals
    });
  } catch (error) {
    return res.status(500).json({ error: 'Failed to build report response' });
  }
});

app.listen(port, () => {
  console.log(`Reports API listening on port ${port}`);
});
