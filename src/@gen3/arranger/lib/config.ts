/**
 * Encapsulate configuration for the arranger server.
 */
export class Configuration {
  esEndpoint: string = 'esproxy-service:9200';
  /**
   * @property arboristEndpoint
   * Note: a value of 'mock' indicates a mock arborist
   */
  // Ordinarily use something like this:
  // arboristEndpoint: string = 'http://arborist-service';
  // (NOTE: there is no trailing slash.)
  arboristEndpoint: string = 'mock';
  mockArboristResources = ['Proj-1'];
  /**
   * @property projectId
   * Arranger will query the elastic-search index with name: arranger-projects-$Id
   */
  projectId: string = 'dev';
  graphqlOptions: {[key: string]: any} = {};
  authFilterNodeType: string = 'case';
  authFilterField: string = 'project';
  authFilterFieldParser = (authField: string): string => {
    return authField;
  };

  /**
   * @property debug
   * Enable verbose logging
   */
  debug: boolean = false;
}

export const singleton = new Configuration()

// Set default values based on environment variables
if (process.env['GEN3_DEBUG']) {
  singleton.debug = true;
}
if (process.env['GEN3_ES_ENDPOINT']) {
  singleton.esEndpoint = process.env['GEN3_ES_ENDPOINT'];
}
if (process.env['GEN3_ARBORIST_ENDPOINT']) {
  singleton.arboristEndpoint = process.env['GEN3_ARBORIST_ENDPOINT'];
}
if (process.env['GEN3_AUTH_FILTER_FIELD']) {
  singleton.authFilterField = process.env['GEN3_AUTH_FILTER_FIELD'];
}
if (process.env['GEN3_AUTH_FILTER_NODE_TYPE']) {
  singleton.authFilterNodeType = process.env['GEN3_AUTH_FILTER_NODE_TYPE'];
}
if (process.env['GEN3_PROJECT_ID']) {
  singleton.projectId = process.env['GEN3_PROJECT_ID'];
}
