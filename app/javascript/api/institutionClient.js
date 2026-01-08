// Institution API Client
// Provides methods for interacting with the institution management API
// Implements error handling and security checks

class InstitutionClient {
  constructor(baseURL = '/api/v1') {
    this.baseURL = baseURL;
  }

  // Helper method for API requests
  async request(endpoint, options = {}) {
    const url = `${this.baseURL}${endpoint}`;
    const headers = {
      'Content-Type': 'application/json',
      ...options.headers
    };

    // Add auth token if available
    const token = this.getAuthToken();
    if (token) {
      headers['X-Auth-Token'] = token;
    }

    try {
      const response = await fetch(url, {
        method: options.method || 'GET',
        headers,
        body: options.body ? JSON.stringify(options.body) : undefined
      });

      if (!response.ok) {
        const error = await response.json().catch(() => ({ error: 'Unknown error' }));
        throw new Error(error.error || `HTTP ${response.status}`);
      }

      return await response.json();
    } catch (error) {
      console.error('API Error:', error);
      throw error;
    }
  }

  getAuthToken() {
    // Get from localStorage or session
    return localStorage.getItem('auth_token') || sessionStorage.getItem('auth_token');
  }

  // Institution Management
  async getInstitutions() {
    return this.request('/institutions');
  }

  async getInstitution(id) {
    return this.request(`/institutions/${id}`);
  }

  async createInstitution(data) {
    return this.request('/institutions', {
      method: 'POST',
      body: { institution: data }
    });
  }

  async updateInstitution(id, data) {
    return this.request(`/institutions/${id}`, {
      method: 'PATCH',
      body: { institution: data }
    });
  }

  async deleteInstitution(id) {
    return this.request(`/institutions/${id}`, {
      method: 'DELETE'
    });
  }

  // Invitation Management
  async getInvitations(institutionId, options = {}) {
    const params = new URLSearchParams();
    if (options.showUsed) params.append('show_used', 'true');

    return this.request(`/admin/invitations?${params.toString()}`, {
      headers: { 'X-Institution-ID': institutionId }
    });
  }

  async createInvitation(institutionId, email, role) {
    return this.request('/admin/invitations', {
      method: 'POST',
      body: {
        institution_id: institutionId,
        email,
        role
      }
    });
  }

  async revokeInvitation(institutionId, invitationId) {
    return this.request(`/admin/invitations/${invitationId}`, {
      method: 'DELETE',
      headers: { 'X-Institution-ID': institutionId }
    });
  }

  // Invitation Acceptance
  async validateInvitation(token) {
    return this.request(`/admin/invitation_acceptance/validate?token=${encodeURIComponent(token)}`);
  }

  async acceptInvitation(token, email) {
    return this.request('/admin/invitation_acceptance', {
      method: 'POST',
      body: { token, email }
    });
  }

  // Security Events
  async getSecurityEvents(filters = {}) {
    const params = new URLSearchParams();
    Object.keys(filters).forEach(key => {
      if (filters[key]) params.append(key, filters[key]);
    });

    return this.request(`/admin/security_events?${params.toString()}`);
  }

  async exportSecurityEvents(filters = {}) {
    const params = new URLSearchParams();
    Object.keys(filters).forEach(key => {
      if (filters[key]) params.append(key, filters[key]);
    });

    // This returns a CSV file download
    const url = `${this.baseURL}/admin/security_events/export?${params.toString()}`;
    const token = this.getAuthToken();

    const response = await fetch(url, {
      headers: token ? { 'X-Auth-Token': token } : {}
    });

    if (!response.ok) {
      throw new Error('Export failed');
    }

    return response.blob();
  }

  async getSecurityAlerts() {
    return this.request('/admin/security_events/alerts');
  }
}

// Singleton instance
const institutionClient = new InstitutionClient();

export default institutionClient;