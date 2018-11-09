import { readFileSync } from 'fs';

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
  authFilterNodeTypes: string[] = ['case'];
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
if (process.env['GEN3_PROJECT_ID']) {
  singleton.projectId = process.env['GEN3_PROJECT_ID'];
}

try {
  const config_filepath = process.env['ARRANGER_CONFIG_FILEPATH'];
  const config = JSON.parse(readFileSync(config_filepath).toString());
  if (config['debug']) {
    singleton.debug = true;
  }
  if (config['es_endpoint']) {
    singleton.esEndpoint = config['es_endpoint'];
  }
  if (config['arborist_auth_endpoint']) {
    singleton.arboristEndpoint = config['arborist_auth_endpoint'];
  }
  if (config['auth_filter_field']) {
    singleton.authFilterField = config['auth_filter_field'];
  }
  if (config['auth_filter_node_types']) {
    singleton.authFilterNodeTypes = config['auth_filter_node_types'];
  } else if (config['auth_filter_node_type']) {
    // backwards compatibility
    // (updated `auth_filter_node_type` -> `auth_filter_node_types`)
    singleton.authFilterNodeTypes = [config['auth_filter_node_type']];
  }
  if (config['project_id']) {
    singleton.projectId = config['project_id'];
  }
  console.log(singleton);
}
catch(e) {
    console.log("couldn't load expected arranger config file");
    console.log(e);
}
