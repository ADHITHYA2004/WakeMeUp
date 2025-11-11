import 'dotenv/config';
import express from 'express';
import cors from 'cors';
import mysql from 'mysql2/promise';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';

const app = express();
app.use(cors());
app.use(express.json());

const {
  DB_HOST = '127.0.0.1',
  DB_PORT = '3306',
  DB_USER = 'root',
  DB_PASSWORD = '#Root1234',
  DB_NAME = 'wakemeup',
  PORT = 4000,
  JWT_SECRET = 'dev_secret_change_me',
} = process.env;

let pool;
async function getPool() {
  if (!pool) {
    // Step 1: ensure database exists using a bootstrap connection (no database selected)
    const bootstrap = await mysql.createConnection({
      host: DB_HOST,
      port: Number(DB_PORT),
      user: DB_USER,
      password: DB_PASSWORD
    });
    await bootstrap.query(`CREATE DATABASE IF NOT EXISTS \`${DB_NAME}\``);
    await bootstrap.end();

    // Step 2: create pool bound to the database
    pool = mysql.createPool({
      host: DB_HOST,
      port: Number(DB_PORT),
      user: DB_USER,
      password: DB_PASSWORD,
      database: DB_NAME,
      waitForConnections: true,
      connectionLimit: 10,
      queueLimit: 0
    });
    // ensure tables exist
    await pool.query(`
      CREATE TABLE IF NOT EXISTS destinations (
        id INT AUTO_INCREMENT PRIMARY KEY,
        name VARCHAR(255) NOT NULL,
        latitude DOUBLE NOT NULL,
        longitude DOUBLE NOT NULL,
        created_at DATETIME NOT NULL
      )
    `);
    await pool.query(`
      CREATE TABLE IF NOT EXISTS users (
        id INT AUTO_INCREMENT PRIMARY KEY,
        email VARCHAR(255) NOT NULL UNIQUE,
        password_hash VARCHAR(255) NOT NULL,
        created_at DATETIME NOT NULL
      )
    `);
  }
  return pool;
}

app.get('/api/health', (_req, res) => {
  res.json({ ok: true });
});

// Debug: list tables to verify schema
app.get('/api/debug/tables', async (_req, res) => {
  try {
    const p = await getPool();
    const [rows] = await p.query('SHOW TABLES');
    res.json(rows);
  } catch (e) {
    res.status(500).json({ error: String(e) });
  }
});

// Debug: list users (email only) to verify signup inserts
app.get('/api/debug/users', async (_req, res) => {
  try {
    const p = await getPool();
    const [rows] = await p.query('SELECT id, email, created_at FROM users ORDER BY id DESC LIMIT 50');
    res.json(rows);
  } catch (e) {
    res.status(500).json({ error: String(e) });
  }
});

// Debug: show current DB config (safe subset)
app.get('/api/debug/config', (_req, res) => {
  res.json({
    host: process.env.DB_HOST || '127.0.0.1',
    port: Number(process.env.DB_PORT || '3306'),
    database: process.env.DB_NAME || 'wakemeup'
  });
});

// Simple auth middleware (optional use)
function authMiddleware(req, res, next) {
  const authHeader = req.headers.authorization || '';
  const token = authHeader.startsWith('Bearer ') ? authHeader.slice(7) : null;
  if (!token) return res.status(401).json({ error: 'Missing token' });
  try {
    const payload = jwt.verify(token, JWT_SECRET);
    req.user = payload;
    next();
  } catch (e) {
    return res.status(401).json({ error: 'Invalid token' });
  }
}

// Auth routes
app.post('/api/auth/signup', async (req, res) => {
  const { email, password } = req.body || {};
  if (!email || !password) {
    return res.status(400).json({ error: 'Email and password required' });
  }
  try {
    const p = await getPool();
    const passwordHash = await bcrypt.hash(password, 10);
    const createdAt = new Date();
    await p.execute(
      'INSERT INTO users (email, password_hash, created_at) VALUES (?, ?, ?)',
      [email, passwordHash, createdAt]
    );
    console.log('Signup OK for', email);
    res.status(201).json({ ok: true });
  } catch (e) {
    if (String(e).includes('Duplicate')) {
      return res.status(409).json({ error: 'Email already in use' });
    }
    res.status(500).json({ error: String(e) });
  }
});

app.post('/api/auth/login', async (req, res) => {
  const { email, password } = req.body || {};
  if (!email || !password) {
    return res.status(400).json({ error: 'Email and password required' });
  }
  try {
    const p = await getPool();
    const [rows] = await p.execute('SELECT * FROM users WHERE email = ?', [email]);
    const user = Array.isArray(rows) ? rows[0] : null;
    if (!user) return res.status(401).json({ error: 'Invalid credentials' });
    const ok = await bcrypt.compare(password, user.password_hash);
    if (!ok) return res.status(401).json({ error: 'Invalid credentials' });
    const token = jwt.sign({ userId: user.id, email: user.email }, JWT_SECRET, { expiresIn: '7d' });
    res.json({ token });
  } catch (e) {
    res.status(500).json({ error: String(e) });
  }
});

// Authenticated user profile
app.get('/api/auth/profile', authMiddleware, async (req, res) => {
  try {
    const p = await getPool();
    const [rows] = await p.execute(
      'SELECT id, email, created_at FROM users WHERE id = ?',
      [req.user.userId]
    );
    const user = Array.isArray(rows) ? rows[0] : null;
    if (!user) return res.status(404).json({ error: 'User not found' });
    res.json({ id: user.id, email: user.email, createdAt: user.created_at });
  } catch (e) {
    res.status(500).json({ error: String(e) });
  }
});

// Stateless logout (client deletes JWT). Kept for symmetry/analytics.
app.post('/api/auth/logout', authMiddleware, (_req, res) => {
  // If token blacklisting is desired, implement here.
  res.json({ ok: true });
});

// Protect all /api/destinations routes
app.use('/api/destinations', authMiddleware);

app.get('/api/destinations', async (_req, res) => {
  try {
    const p = await getPool();
    const [rows] = await p.query('SELECT * FROM destinations ORDER BY created_at DESC');
    res.json(rows);
  } catch (e) {
    res.status(500).json({ error: String(e) });
  }
});

app.post('/api/destinations', async (req, res) => {
  const { name, latitude, longitude } = req.body || {};
  const lat = Number(latitude);
  const lng = Number(longitude);
  if (
    typeof name !== 'string' ||
    name.trim().length === 0 ||
    !Number.isFinite(lat) ||
    !Number.isFinite(lng)
  ) {
    return res.status(400).json({
      error: 'Invalid payload',
      details: {
        nameValid: typeof name === 'string' && name.trim().length > 0,
        latitudeReceived: latitude,
        longitudeReceived: longitude
      }
    });
  }
  try {
    const p = await getPool();
    const createdAt = new Date();
    const [result] = await p.execute(
      'INSERT INTO destinations (name, latitude, longitude, created_at) VALUES (?, ?, ?, ?)',
      [name.trim(), lat, lng, createdAt]
    );
    console.log('Destination inserted id=', result.insertId, 'name=', name);
    res.status(201).json({ id: result.insertId });
  } catch (e) {
    res.status(500).json({ error: String(e) });
  }
});

app.delete('/api/destinations/:id', async (req, res) => {
  const id = Number(req.params.id);
  if (!id) return res.status(400).json({ error: 'Invalid id' });
  try {
    const p = await getPool();
    await p.execute('DELETE FROM destinations WHERE id=?', [id]);
    res.json({ ok: true });
  } catch (e) {
    res.status(500).json({ error: String(e) });
  }
});

// Initialize database on startup
getPool().then(() => {
  console.log(`Database '${DB_NAME}' ready (tables: destinations, users)`);
}).catch(err => {
  console.error('Failed to initialize database:', err);
  process.exit(1);
});

app.listen(PORT, () => {
  console.log(`API on http://localhost:${PORT}`);
});


