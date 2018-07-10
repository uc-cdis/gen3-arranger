import { singleton as config } from './config.js';

export interface Arborist {
  hello():Promise<string>;
}

class MockArborist implements Arborist {
  hello():Promise<string> { return Promise.resolve("hello"); }
}

export const singleton = config.arboristEndpoint == 'mock' ? new MockArborist() : null;
