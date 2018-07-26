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
import { singleton as arborist } from '../lib/arboristClient';


const app = express();
const server = new Server(app);
const io = socketIO(server);

const router = express.Router();
router.use(bodyParser.urlencoded({ extended: false }));
router.use(bodyParser.json({ limit: '50mb' }));

app.use(function(req, res, next) {
  res.header("Access-Control-Allow-Origin", "*");
  res.header("Access-Control-Allow-Headers", "Origin, X-Requested-With, Content-Type, Accept");
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
  if (!status.isHealthy) {
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
        if (parts[0] == 'Bearer') {
          (req as any).jwt = parts[1];
        }
      }
    }
    next();
  }
);

const port = 3000;
const es = new elasticsearch.Client({ host: config.esEndpoint });

const graphqlMiddleware = {
  // Pass `jwt` field on the context through to the middleware functions.
  context: ({ jwt }) => ({ jwt }),
  middleware: [arborist.checkAuthorization],
};
const graphqlOptions = {...graphqlMiddleware, ...config.graphqlOptions}
//const graphqlOptions = config.graphqlOptions

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
  }
).then(
  () => {
    app.get('/*', function(req, res) {
      res.status(404).json({ "message": "no such path" });
    });    
    server.listen(port, () => {
      console.log(`Listening on port ${port}`);
    });
  }
);
