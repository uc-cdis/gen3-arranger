/**
 * Encapsulate configuration for the arranger server.
 */
export class Configuration {
  esEndpoint: string = 'http://esproxy-service';
  // note: a value of 'mock' indicates a mock arborist
  arboristEndpoint: string = 'http://arborist-service';
}

export const singleton = new Configuration();

// Set default values based on environment variables
if (process.env['GEN3_ES_ENDPOINT']) {
  singleton.esEndpoint = process.env['GEN3_ES_ENDPOINT'];
}
if (process.env['GEN3_ARBORIST_ENDPOINT']) {
  singleton.arboristEndpoint = process.env['GEN3_ARBORIST_ENDPOINT'];
}
