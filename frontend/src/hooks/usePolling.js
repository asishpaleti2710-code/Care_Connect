import { useEffect } from 'react';

// Run `callback` immediately and then on a fixed interval, clearing it on unmount.
export function usePolling(callback, intervalMs, deps = []) {
  useEffect(() => {
    callback();
    const timer = setInterval(callback, intervalMs);
    return () => clearInterval(timer);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, deps);
}
