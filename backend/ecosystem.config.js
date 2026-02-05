module.exports = {
  apps: [
    {
      name: 'muchtodo-api',
      script: './main',
      instances: 'max',
      exec_mode: 'cluster',
      env: {
        NODE_ENV: 'development',
      },
      env_production: {
        NODE_ENV: 'production',
      },
    },
  ],
};
