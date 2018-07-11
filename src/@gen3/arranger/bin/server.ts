import * as express from 'express';
import { Server } from 'http';
import socketIO = require('socket.io');
import "regenerator-runtime/runtime";
import Arranger from '@arranger/server';
import { checkHealth } from '../lib/healthCheck';
import { singleton as config } from '../lib/config';


const app = express();
const http = new Server(app);
const io = socketIO(http);

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

const port = 3000;

Arranger({
  io,
  projectId: config.projectId,
  esHost: config.esEndpoint,
  graphqlOptions: {
    //context: ({ jwt }) => ({ jwt }),
    //middleware: [onlyAdminMutations]
  }
}).then(router => {
  app.use(router);
  http.listen(port, () => {
    console.log(`⚡️ Listening on port ${port} ⚡️`);
  });
});

