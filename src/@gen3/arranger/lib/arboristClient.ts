import fetch from 'node-fetch';
import { singleton as config } from './config';

export interface Arborist {
  // baseEndpoint is the URL for the arborist microservice (without a `/`).
  baseEndpoint: string;
  // listAuthorizedResources should take a JWT from a request and, according
  // to arborist and according to the policies granted in the token, return a
  // list of the resources which can be viewed.
  listAuthorizedResources: (string) => string[];
}

class MockArborist implements Arborist {
  baseEndpoint;
  listAuthorizedResources = (jwt: string): string[] => {
    return ['Proj-1'];
  }
}

class ArboristClient implements Arborist {
  baseEndpoint;
  constructor(arboristEndpoint: string) {
    this.baseEndpoint = arboristEndpoint;
  }
  listAuthorizedResources = (jwt: string): string[] => {
    if (!jwt) {
      return [];
    }
    // Make request to arborist for list of resources with access
    const resourcesEndpoint = this.baseEndpoint + '/auth/resources'
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
