const { execSync } = require('child_process');

// Apply patches to node_modules
require('../patches/fix-pglite-prisma-bytes.cjs');

if (process.env.SKIP_HOPPERS_WIRE_BUILD === '1') {
  console.log('[postinstall] SKIP_HOPPERS_WIRE_BUILD=1, skipping @hoppers-app/hoppers-wire build');
  process.exit(0);
}

execSync('yarn workspace @hoppers-app/hoppers-wire build', {
  stdio: 'inherit',
});
