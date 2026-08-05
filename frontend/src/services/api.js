const getBaseUrl = (defaultPort, envVar) => {
  if (envVar) return envVar;
  return "";
};

const BACKEND_URL = getBaseUrl(8000, import.meta.env.VITE_API_URL);
const AI_AGENT_URL = getBaseUrl(8001, import.meta.env.VITE_AI_URL);

async function request(endpoint, options = {}, isAI = false) {
  const baseUrl = isAI ? AI_AGENT_URL : BACKEND_URL;
  const token = localStorage.getItem("careconnect_token");

  const headers = {
    "Content-Type": "application/json",
    ...options.headers,
  };

  if (token) {
    headers["Authorization"] = `Bearer ${token}`;
  }

  const response = await fetch(`${baseUrl}${endpoint}`, {
    ...options,
    headers,
  });

  if (response.status === 204) {
    return null;
  }

  const data = await response.json().catch(() => ({}));

  if (!response.ok) {
    throw new Error(data.detail || "An unexpected error occurred");
  }

  return data;
}

export const api = {
  // Auth
  login: (email, password) =>
    request("/api/auth/login", {
      method: "POST",
      body: JSON.stringify({ email, password }),
    }),

  register: (email, password, full_name, role) =>
    request("/api/auth/register", {
      method: "POST",
      body: JSON.stringify({ email, password, full_name, role }),
    }),

  getMe: () => request("/api/auth/me"),

  // Residents
  getResidents: () => request("/api/residents"),
  getResident: (id) => request(`/api/residents/${id}`),
  createResident: (residentData) =>
    request("/api/residents", {
      method: "POST",
      body: JSON.stringify(residentData),
    }),
  updateResident: (id, residentData) =>
    request(`/api/residents/${id}`, {
      method: "PUT",
      body: JSON.stringify(residentData),
    }),
  deleteResident: (id) =>
    request(`/api/residents/${id}`, {
      method: "DELETE",
    }),

  // Guardians
  getGuardians: (residentId) => request(`/api/guardians/resident/${residentId}`),
  addGuardian: (guardianData) =>
    request("/api/guardians", {
      method: "POST",
      body: JSON.stringify(guardianData),
    }),
  deleteGuardian: (id) =>
    request(`/api/guardians/${id}`, {
      method: "DELETE",
    }),

  // Incidents Workflow
  getIncidents: (statusFilter = null) => {
    const query = statusFilter ? `?status_filter=${statusFilter}` : "";
    return request(`/api/incidents${query}`);
  },
  triggerIncident: (incidentData) =>
    request("/api/incidents/trigger", {
      method: "POST",
      body: JSON.stringify(incidentData),
    }),
  acceptIncident: (incidentId) =>
    request(`/api/incidents/${incidentId}/accept`, {
      method: "PUT",
    }),
  updateIncidentStatus: (incidentId, status) =>
    request(`/api/incidents/${incidentId}/status`, {
      method: "PUT",
      body: JSON.stringify({ status }),
    }),
  getAnalytics: () => request("/api/incidents/analytics"),

  // AI Module
  classifyEmergency: (description) =>
    request(
      "/api/ai/classify-emergency",
      {
        method: "POST",
        body: JSON.stringify({ description }),
      },
      true
    ),
  analyzeNotes: (full_name, age, medical_notes) =>
    request(
      "/api/ai/analyze-notes",
      {
        method: "POST",
        body: JSON.stringify({ full_name, age, medical_notes }),
      },
      true
    ),
  chatAI: (query, context = null) =>
    request(
      "/api/ai/chat",
      {
        method: "POST",
        body: JSON.stringify({ query, context }),
      },
      true
    ),

  // Settings & Profile Management
  updateProfile: (profileData) =>
    request("/api/auth/profile", {
      method: "PUT",
      body: JSON.stringify(profileData),
    }),

  changePassword: (current_password, new_password) =>
    request("/api/auth/change-password", {
      method: "PUT",
      body: JSON.stringify({ current_password, new_password }),
    }),

  deleteAccount: () =>
    request("/api/auth/account", {
      method: "DELETE",
    }),

  getActivities: () => request("/api/auth/activities"),
};
