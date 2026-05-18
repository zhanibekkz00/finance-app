const { Client } = require('pg');
const client = new Client({
  connectionString: "postgresql://postgres:1234@localhost:5432/postgres"
});
client.connect()
  .then(() => client.query('CREATE DATABASE finance_app'))
  .then(() => {
    console.log('Database finance_app created or already exists');
    client.end();
  })
  .catch(err => {
    console.error('Error creating database:', err.message);
    client.end();
  });
