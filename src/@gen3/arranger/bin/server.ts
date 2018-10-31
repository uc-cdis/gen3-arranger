import { get } from 'lodash';
import * as elasticsearch from 'elasticsearch';
import * as express from 'express';
import { Server } from 'http';
import * as socketIO from 'socket.io';
import 'regenerator-runtime/runtime';
import * as bodyParser from 'body-parser';
import startProject from '@arranger/server/dist/startProject';
import { checkHealth } from '../lib/healthCheck';
import { singleton as config } from '../lib/config';
import { authFilter } from '../lib/graphqlMiddleware';

const app = express();
const server = new Server(app);
const io = socketIO(server);

const router = express.Router();
router.use(bodyParser.urlencoded({ extended: false }));
router.use(bodyParser.json({ limit: '50mb' }));

app.use(function(req, res, next) {
  // intercept OPTIONS method
  if ('OPTIONS' == req.method) {
    res.send(204);
  }
  else {
    next();
  }
});

app.use(router);

app.get('/_status', async function(req, res) {
  console.log('Processing /_status');
  const status = await checkHealth();
  if (!status.isHealthy || !projectStarted) {
    res = res.status(500);
  }
  res.json(status);
});

// Add middleware to attach JWT from the authorization header to the context.
app.use(
  (req, res, next) => {
    (req as any).jwt = null;
    const authHeader = get(req.headers, 'authorization', null);
    if (authHeader != null) {
      const parts = authHeader.split(' ');
      if (parts.length == 2) {
        if (parts[0].toLowerCase() == 'bearer') {
          (req as any).jwt = parts[1];
        }
      }
    }
    next();
  }
);

const port = 3000;
const es = new elasticsearch.Client({ host: config.esEndpoint });

// Add some GraphQL middleware which applies an authorization filter to GraphQL
// requests by checking permissions from arborist.
const graphqlMiddleware = {
  // Pass `jwt` field on the context through to the middleware funcitons.
  context: ({ jwt }) => ({ jwt }),
  middleware: [authFilter],
};
// These graphqlOptions get passed to arranger for setting up the arranger
// server with this middleware.
const graphqlOptions = {...graphqlMiddleware, ...config.graphqlOptions}

// tracks status of whether project started successfully or not
// used to determine health status
let projectStarted = false;

startProject({
  es,
  io,
  id: config.projectId,
  graphqlOptions: graphqlOptions,
}).then(
  (router) => {
    app.use('/search', router);
  },
  (err) => {
    console.log('WARNING: arranger project not started', err);
    projectStarted = false;
  }
).then(
  () => {
    app.get('/*', function(req, res) {
      res.status(404).json({ "message": "no such path" });
    });    
    server.listen(port, () => {
      console.log(`Listening on port ${port}`);
    });
    projectStarted = true;
  }
);
