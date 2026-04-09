import { Link } from 'react-router-dom'

export default function NotFoundPage() {
  return (
    <div className="not-found">
      <h1 className="not-found-title">404</h1>
      <p className="not-found-message">Page not found.</p>
      <Link to="/" className="btn btn-primary">
        Go home
      </Link>
    </div>
  )
}
