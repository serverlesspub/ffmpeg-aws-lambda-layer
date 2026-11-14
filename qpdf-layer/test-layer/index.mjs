import { spawnSync } from 'node:child_process';
import { existsSync, writeFileSync } from 'node:fs';

// qpdf exit codes: 0 = success, 3 = success with warnings, 2 = error.
function run(cmd, args, okCodes = [0]) {
  const r = spawnSync(cmd, args, { encoding: 'utf8', timeout: 30000 });
  return {
    command: [cmd, ...args].join(' '),
    stdout: (r.stdout || '').trim(),
    stderr: (r.stderr || r.error?.message || '').trim(),
    returncode: r.status,
    passed: okCodes.includes(r.status),
  };
}

// Minimal one-page PDF with no xref table. qpdf reconstructs the xref
// (exit 3 = warnings) and writes a valid file. Note: `qpdf --empty` makes a
// zero-page PDF that `--check` rejects, so it is not usable as a fixture.
const RAW_PDF =
  '%PDF-1.4\n' +
  '1 0 obj<</Type/Catalog/Pages 2 0 R>>endobj\n' +
  '2 0 obj<</Type/Pages/Kids[3 0 R]/Count 1>>endobj\n' +
  '3 0 obj<</Type/Page/Parent 2 0 R/MediaBox[0 0 612 792]/Resources<<>> >>endobj\n' +
  'trailer<</Size 4/Root 1 0 R>>\n%%EOF\n';

export const handler = async () => {
  writeFileSync('/tmp/raw.pdf', RAW_PDF);
  const checks = [
    run('qpdf', ['--version']),
    run('qpdf', ['/tmp/raw.pdf', '/tmp/a.pdf'], [0, 3]), // repair
    run('qpdf', ['--check', '/tmp/a.pdf']),
    run('qpdf', ['--encrypt', 'user', 'owner', '256', '--', '/tmp/a.pdf', '/tmp/enc.pdf']),
    run('qpdf', ['--password=user', '--decrypt', '/tmp/enc.pdf', '/tmp/dec.pdf']),
    run('qpdf', ['--linearize', '/tmp/dec.pdf', '/tmp/lin.pdf']),
    run('qpdf', ['--check-linearization', '/tmp/lin.pdf']),
  ];
  const npages = run('qpdf', ['--show-npages', '/tmp/lin.pdf']);
  npages.passed = npages.passed && npages.stdout === '1';
  checks.push(npages);

  // Only when the ffmpeg layer is attached: proves both layers coexist in /opt.
  if (existsSync('/opt/bin/ffmpeg')) {
    checks.push(run('ffmpeg', ['-version']));
  }

  const passed = checks.filter((c) => c.passed).length;
  const summary = {
    all_passed: passed === checks.length,
    total: checks.length,
    passed,
    failed: checks.length - passed,
  };

  return {
    statusCode: summary.all_passed ? 200 : 500,
    body: JSON.stringify({ summary, checks }, null, 2),
  };
};
