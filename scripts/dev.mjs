import { spawn } from 'node:child_process';

console.log('[Dev] Iniciando servidor de API Backend en http://localhost:3000...');
const api = spawn('node', ['--experimental-strip-types', 'dev-server.mjs'], {
  stdio: 'inherit',
  shell: true,
});

console.log('[Dev] Iniciando servidor Flutter Web en http://localhost:8080...');
const flutter = spawn('flutter', ['run', '-d', 'web-server', '--web-port', '8080', '--web-hostname', 'localhost'], {
  stdio: 'inherit',
  shell: true,
});

function cleanup() {
  console.log('\n[Dev] Deteniendo servidores...');
  try { api.kill(); } catch {}
  try { flutter.kill(); } catch {}
  process.exit(0);
}

process.on('SIGINT', cleanup);
process.on('SIGTERM', cleanup);

