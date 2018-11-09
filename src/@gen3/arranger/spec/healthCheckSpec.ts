import { getHealth, setProjectStarted } from '../lib/healthCheck';

describe('the healthCheckModule', function() {
  it('should be healthy initially', async function() {
    const status = await getHealth();
    expect(status.isHealthy).toBe(true);
  });

  it('after setProjectStarted true isHealthy true', async function() {
    setProjectStarted(true);
    const status = await getHealth();
    expect(status.isHealthy).toBe(true);
  });

  it('after setProjectStarted false has isHealthy false', async function() {
    setProjectStarted(false);
    const status = await getHealth();
    expect(status.isHealthy).toBe(false);
  });
});
