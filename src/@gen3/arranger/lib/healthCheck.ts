
export interface HealthStatus {
  isHealthy: boolean;
  message: string;
  projectStarted: boolean;
}

// Manages health state internally
const healthStatus = {
  isHealthy: true,
  message: 'Project not yet started',
  projectStarted: null,
};

/**
 * Updates the isHealthy attribute by checking relevant health properties
 * Used for determining if arranger is healthy
 */
function updateIsHealthy() {
  healthStatus.isHealthy = healthStatus.isHealthy
      && healthStatus.projectStarted !== false;
}

/**
 * Returns current Health Status
 * @returns {Promise<HealthStatus>}
 */
export function getHealth():Promise<HealthStatus> {
  updateIsHealthy();
  return Promise.resolve({...healthStatus});
}

/**
 * Sets the projectStarted attribute of health status
 * @param {boolean} success
 * @returns {HealthStatus}
 */
export function setProjectStarted(success: boolean):HealthStatus {
  healthStatus.projectStarted = success;
  healthStatus.message = success ? healthStatus.message : 'Failed to start project';
  return {...healthStatus}
}