const { execSync } = require('child_process');

try {
  console.log('1. Staging files...');
  execSync('git add .', { stdio: 'inherit' });

  console.log('2. Committing changes...');
  execSync('git commit -m "Fix member list and leader dashboard member count integration"', { stdio: 'inherit' });

  console.log('3. Pushing to origin main...');
  execSync('git push origin main', { stdio: 'inherit' });

  console.log('Git push completed successfully!');
} catch (err) {
  console.error('Git error:', err.message);
}
