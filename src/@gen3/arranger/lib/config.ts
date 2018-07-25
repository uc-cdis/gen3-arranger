/**
 * Encapsulate configuration for the arranger server.
 */
export class Configuration {
  esEndpoint: string = 'esproxy-service:9200';
  /**
   * @property arboristEndpoint
   * Note: a value of 'mock' indicates a mock arborist
   */
  arboristEndpoint: string = 'http://arborist-service';
  /**
   * @property projectId
   * Arranger will query the elastic-search index with name: arranger-projects-$Id
   */
  projectId: string = 'dev';
  graphqlOptions:{[key:string]:string} = {};
}

export const singleton = new Configuration();

// Set default values based on environment variables
if (process.env['GEN3_ES_ENDPOINT']) {
  singleton.esEndpoint = process.env['GEN3_ES_ENDPOINT'];
}
if (process.env['GEN3_ARBORIST_ENDPOINT']) {
  singleton.arboristEndpoint = process.env['GEN3_ARBORIST_ENDPOINT'];
}
if (process.env['GEN3_PROJECT_ID']) {
  singleton.projectId = process.env['GEN3_PROJECT_ID'];
}