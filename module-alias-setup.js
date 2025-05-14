const path = require('path');
const moduleAlias = require('module-alias');

// Define all the aliases needed
moduleAlias.addAliases({
  '~': path.join(__dirname),
  '@root': path.join(__dirname),
  '@config': path.join(__dirname, 'config'),
  '@utils': path.join(__dirname, 'api', 'server', 'utils')
});

console.log('Module aliases set up successfully');
console.log('~ mapped to:', path.join(__dirname)); 