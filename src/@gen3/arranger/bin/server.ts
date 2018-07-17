import * as elasticsearch from 'elasticsearch';
import * as express from 'express';
import { Server } from 'http';
import * as socketIO from 'socket.io';
import 'regenerator-runtime/runtime';
import * as bodyParser from 'body-parser';
import startProject from '@arranger/server/dist/startProject';
import { checkHealth } from '../lib/healthCheck';
import { singleton as config } from '../lib/config';


const app = express();
const server = new Server(app);
const io = socketIO(server);

const router = express.Router();
router.use(bodyParser.urlencoded({ extended: false }));
router.use(bodyParser.json({ limit: '50mb' }));
app.use(router);

app.get('/_status', async function(req, res) {
  console.log('Processing /_status');
  const status = await checkHealth();
  if (!status.isHealthy) {
    res = res.status(500);
  }
  res.json(status);
});


const port = 3000;
const es = new elasticsearch.Client({ host: config.esEndpoint });

startProject(
  { es, io, id: config.projectId, graphqlOptions: config.graphqlOptions }
).then(
  (router) => {
    app.use('/search', router);
  },
  (err) => {
    console.log('WARNING: arranger project not started', err);
  }
).then(
  function() {
    app.get('/*', function(req, res) {
      res.status(404).json({ "message": "no such path" });
    });    
    server.listen(port, () => {
      console.log(`⚡️ Listening on port ${port} ⚡️`);
    });
  }
);
