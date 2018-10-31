import fetch from 'node-fetch';
import { singleton as config } from './config';

export interface Arborist {
  // baseEndpoint is the URL for the arborist microservice (without a `/`).
  baseEndpoint: string;
  // listAuthorizedResources should take a JWT from a request and, according
  // to arborist and according to the policies granted in the token, return a
  // list of the resources which can be viewed.
  listAuthorizedResources: (string) => Promise<object>;
}

class MockArborist implements Arborist {
  baseEndpoint;
  listAuthorizedResources = (jwt: string): Promise<object> => {
    return Promise.resolve(config.mockArboristResources);
  }
}

class ArboristClient implements Arborist {
  baseEndpoint;
  constructor(arboristEndpoint: string) {
    this.baseEndpoint = arboristEndpoint;
  }
  listAuthorizedResources = (jwt: string): Promise<object> => {
    if (!jwt) {
      console.log("no JWT in the context; returning no resources");
      return Promise.resolve({});
    }
    // Make request to arborist for list of resources with access
    const resourcesEndpoint = this.baseEndpoint + '/auth/resources'
    return fetch(
      resourcesEndpoint,
      {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ user: { token: jwt } }),
      }
    ).then(
        (response) => {
            if (response.ok) {
                return response.json()
            }
            else {
                console.log(response.json())
                return {}
            }},
        (err) => {
            console.log(err);
            return {};
        }
    );
  }
}

export const singleton = config.arboristEndpoint == 'mock'
  ? new MockArborist()
  : new ArboristClient(config.arboristEndpoint);
