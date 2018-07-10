import { checkHealth } from '../lib/healthCheck';

describe('the healthCheckModule', function() {
  it('should be healthy', async function() {
    const status = await checkHealth();
    expect(status.isHealthy).toBe(true);
  });
});
