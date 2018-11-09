
export interface HealthStatus {
  isHealthy: boolean;
  message: string;
  projectStarted: boolean;
}

// Manages health state internally
const healthStatus = {
  isHealthy: true,
  message: 'ok',
  projectStarted: false,
};

/**
 * Returns current Health Status
 * @returns {Promise<HealthStatus>}
 */
export function getHealth():Promise<HealthStatus> {
  return Promise.resolve({...healthStatus});
}

/**
 * Sets the projectStarted attribute of health status
 * @param {boolean} success
 * @returns {HealthStatus}
 */
export function setProjectStarted(success: boolean):HealthStatus {
  healthStatus.projectStarted = success;
  return {...healthStatus}
}