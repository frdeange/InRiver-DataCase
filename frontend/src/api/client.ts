import axios, { AxiosInstance, InternalAxiosRequestConfig } from "axios";
import { apiConfig } from "../auth/msalConfig";

let tokenGetter: (() => Promise<string>) | null = null;

export function setTokenGetter(getter: () => Promise<string>) {
  tokenGetter = getter;
}

const client: AxiosInstance = axios.create({
  baseURL: apiConfig.baseUrl,
});

client.interceptors.request.use(async (config: InternalAxiosRequestConfig) => {
  if (tokenGetter) {
    const token = await tokenGetter();
    config.headers.set("Authorization", `Bearer ${token}`);
  }
  return config;
});

client.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response?.status === 401) {
      window.location.href = "/login";
    }
    return Promise.reject(error);
  }
);

export default client;
