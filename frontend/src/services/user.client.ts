const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:5000/api';

export const UserService = {
    async getDashboard() {
        const token = localStorage.getItem('token');
        const res = await fetch(`${API_BASE_URL}/user/dashboard`, {
            headers: {
                'Authorization': `Bearer ${token}`
            }
        });
        return await res.json();
    }
};
