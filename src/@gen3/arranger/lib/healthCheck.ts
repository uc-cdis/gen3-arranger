
export interface HealthStatus {
  isHealthy: boolean;
  message: string;
};

/**
 * Perform whatever checks are necessary -
 *   maybe do a simple elastic search query or whatever
 */
export function checkHealth():Promise<HealthStatus> {
  return Promise.resolve({ isHealthy: true, message: "ok" });
}