import * as express from 'express';
import { checkHealth } from '../lib/healthCheck';
const app = express();

app.get('/_status', async function(req, res) {
  console.log('Processing /_status');
  const status = await checkHealth();
  if (!status.isHealthy) {
    res = res.status(500);
  }
  res.json(status);
});

app.get('/*', function(req, res) {
  res.status(404).json({ "message": "no such path" });
});

app.listen(3000, function() {
  console.log('Server listening at http://localhost:3000/');
});
