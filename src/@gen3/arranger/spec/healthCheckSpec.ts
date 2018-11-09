import { getHealth, setProjectStarted } from '../lib/healthCheck';

describe('the healthCheckModule', function() {
  it('should be healthy', async function() {
    const status = await getHealth();
    expect(status.isHealthy).toBe(true);
  });

  it('after setProjectStarted true has projectStarted true', async function() {
    setProjectStarted(true);
    const status = await getHealth();
    expect(status.projectStarted).toBe(true);
  });

  it('after setProjectStarted false has projectStarted false', async function() {
    setProjectStarted(false);
    const status = await getHealth();
    expect(status.projectStarted).toBe(false);
  });
});
