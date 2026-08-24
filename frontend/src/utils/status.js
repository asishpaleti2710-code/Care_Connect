export const IN_PROGRESS_INCIDENT_STATUSES = ['Accepted', 'In Progress'];
export const ACTIVE_INCIDENT_STATUSES = ['Pending', ...IN_PROGRESS_INCIDENT_STATUSES];

// Map an incident status to the matching `badge-*` CSS modifier.
export function incidentBadgeClass(status) {
  if (status === 'Resolved') return 'badge badge-safe';
  if (status === 'Pending') return 'badge badge-emergency';
  return 'badge badge-alert';
}

// Map a resident status (safe / alert / emergency) to its accent color.
export function residentStatusColor(status) {
  if (status === 'emergency') return '#ef4444';
  if (status === 'alert') return '#f59e0b';
  return '#10b981';
}

// Map a risk level returned by the AI service to the matching `badge-*` modifier.
export function riskBadgeClass(riskLevel) {
  if (riskLevel === 'High') return 'badge badge-emergency';
  if (riskLevel === 'Moderate') return 'badge badge-alert';
  return 'badge badge-safe';
}
