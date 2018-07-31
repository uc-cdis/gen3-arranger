import fetch from 'node-fetch';
import { singleton as config } from './config';

export interface Arborist {
  endpoint: string;
  listAuthorizedResources: (string) => string[];
}

class MockArborist implements Arborist {
  endpoint;
  listAuthorizedResources = (jwt: string): string[] => {
    return ['Proj-1'];
  }
}

class ArboristClient implements Arborist {
  endpoint;
  constructor(arboristEndpoint: string) {
    this.endpoint = arboristEndpoint;
  }
  listAuthorizedResources = (jwt: string): string[] => {
    if (!jwt) {
      return [];
    }
    // Make request to arborist for list of resources with access
    const resourcesEndpoint = this.endpoint + '/auth/resources'
    const resources: string[] = fetch(
      resourcesEndpoint,
      {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ user: { token: jwt } }),
      }
    ).then(
      (response) => response.json().resources,
      (err) => [],
    );
    return resources;
  }
}

export const singleton = config.arboristEndpoint == 'mock'
  ? new MockArborist()
  : new ArboristClient(config.arboristEndpoint);
