import fetch from 'node-fetch';
import { singleton as config } from './config';

export interface Arborist {
  endpoint: string;
  checkAuthorization: {string: Function};
}

class MockArborist implements Arborist {
  endpoint;
  checkAuthorization;
}

class ArboristClient implements Arborist {
  public endpoint;
  public checkAuthorization;
  constructor(arboristEndpoint: string) {
    this.endpoint = arboristEndpoint;
    this.checkAuthorization = {Root: this.authFilter}
  }
  public authFilter = (resolve, parentArg, args, context, info) => {
    // Make request to arborist for list of resources with access
    const resourcesEndpoint = this.endpoint + '/auth/resources'
    const resources: string[] = fetch(
      resourcesEndpoint, 
      {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ user: { token: context.jwt } }),
      }
    ).then(
      (response) => response.json().resources,
      (err) => [],
    );
    // TODO: how to apply filter correctly?
    args = {
      variables: {
        sqon: {
          filter: {
            'op': 'in',
            'content': {
              'field': 'node.project',
              'value': ['Proj-1', 'Proj-2'],
            },
          }
        }
      }
    }
    return resolve(parentArg, args, context, info);
  }
}

export const singleton = config.arboristEndpoint == 'mock'
  ? new MockArborist()
  : new ArboristClient(config.arboristEndpoint);
