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
    return config.mockArboristResources;
  }
}

class ArboristClient implements Arborist {
  baseEndpoint;
  constructor(arboristEndpoint: string) {
    this.baseEndpoint = arboristEndpoint;
  }
  listAuthorizedResources = (jwt: string): string[] => {
    if (!jwt) {
      console.log("no JWT in the context; returning no resources");
      return [];
    }
    // Make request to arborist for list of resources with access
    const resourcesEndpoint = this.baseEndpoint + '/auth/resources'
    console.log("making request to arborist");
    const resources: string[] = fetch(
      resourcesEndpoint,
      {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ request: { token: jwt } }),
      }
    ).then(
      (response) => response.json().resources,
      (err) => {
        console.log(err);
        return []
      }
    );
    console.log("made request to arborist");
    return resources;
  }
}

export const singleton = config.arboristEndpoint == 'mock'
  ? new MockArborist()
  : new ArboristClient(config.arboristEndpoint);
