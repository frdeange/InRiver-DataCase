import axios from "axios"
import type { AxiosInstance, InternalAxiosRequestConfig } from "axios"

const BASE_URL: string = (import.meta.env.VITE_API_URL as string | undefined) ?? ""

let tokenGetter: (() => Promise<string>) | null = null

export function setTokenGetter(getter: () => Promise<string>) {
  tokenGetter = getter
}

const client: AxiosInstance = axios.create({
  baseURL: BASE_URL,
})

client.interceptors.request.use(async (config: InternalAxiosRequestConfig) => {
  if (tokenGetter) {
    const token = await tokenGetter()
    config.headers.set("Authorization", `Bearer ${token}`)
  }
  return config
})

client.interceptors.response.use(
  (response) => response,
  (error: unknown) => {
    if ((error as { response?: { status?: number } }).response?.status === 401) {
      window.location.href = "/login"
    }
    return Promise.reject(error)
  }
)

export default client
