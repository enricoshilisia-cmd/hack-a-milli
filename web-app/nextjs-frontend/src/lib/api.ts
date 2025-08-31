import axios from "axios";

const api = axios.create({
  baseURL: "https://api.skillproof.me.ke/api/",
  headers: {
    "Content-Type": "application/json",
  },
});

// Add interceptor to include auth token
api.interceptors.request.use((config) => {
  const token = localStorage.getItem("token");
  if (token) {
    config.headers.Authorization = `Token ${token}`;
  }
  return config;
});

export default api;